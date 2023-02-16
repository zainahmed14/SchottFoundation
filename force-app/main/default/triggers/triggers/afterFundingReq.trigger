trigger afterFundingReq on outfunds__Funding_Request__c (after insert) {
    List<Id> frId = new List<Id>();
    
    for(outfunds__Funding_Request__c fr: trigger.new){
        frId.add(fr.Id);
    }
    
    Map<Id,outfunds__Funding_Request__c> frNewMap = new Map<Id,outfunds__Funding_Request__c>([Select Id, Grant_Number__c from outfunds__Funding_Request__c where Id IN: frId]);
    
    Map<Id,Decimal> finalAmountMap = new Map<Id,Decimal>();
    
    Map<Id,Id> fpMap = new Map<Id,Id>();  
    
    for(outfunds__Funding_Request__c fr: trigger.new){
        fpMap.put(fr.Id, fr.outfunds__FundingProgram__c);
    }
    
    for(outfunds__Funding_Request__c fr: trigger.new){
        if(fr.outfunds__Status__c == 'Awarded' && fr.outfunds__Awarded_Amount__c != null){
        if(finalAmountMap.containsKey(fr.outfunds__FundingProgram__c)){
            Decimal d = finalAmountMap.get(fr.outfunds__FundingProgram__c);
            d += fr.outfunds__Awarded_Amount__c;
            finalAmountMap.put(fr.Id,d);
        }else{
              finalAmountMap.put(fr.Id,fr.outfunds__Awarded_Amount__c);
        }
    }
    }
    
    Map<Id,outfunds__Funding_Program__c> fpRecordMap = new Map<Id,outfunds__Funding_Program__c>([Select Id,Committed_Amount__c from outfunds__Funding_Program__c where Id IN: fpMap.values()]);
   
    List<sObject> recordsToUpdate = new List<sObject>();
   
    /*for(outfunds__Funding_Request__c fr: trigger.new){
        
        if(fr.outfunds__Status__c == 'Awarded' && fr.outfunds__Awarded_Amount__c != null){
            
            outfunds__Funding_Program__c fp = fpRecordMap.get(fr.outfunds__FundingProgram__c);
            fp.Committed_Amount__c += finalAmountMap.get(fr.outfunds__FundingProgram__c);
            recordsToUpdate.add(fp);
                                                         
            
        }
    }*/

        
    Map<Id,outfunds__Funding_Program__c> fundingProgramMap = new Map<id,outfunds__Funding_Program__c>();

    for (Id i : finalAmountMap.keySet()){

        Id fundingProgramId  = fpMap.containsKey(i) ? fpMap.get(i) : '';
        if(!String.isBlank(fundingProgramId)){
        if(fundingProgramMap.containsKey(fundingProgramId)){
            outfunds__Funding_Program__c temp = fundingProgramMap.get(fundingProgramID);
            Decimal amount =  temp.Committed_Amount__c + finalAmountMap.get(i);
            temp.Committed_Amount__c = amount;
            fundingProgramMap.put(fundingProgramId,temp);
        }  
        else{
            
            outfunds__Funding_Program__c fpNew = fpRecordMap.get(fundingProgramId);
            fpNew.Committed_Amount__c += finalAmountMap.get(i);
            fundingProgramMap.put(fundingProgramId,fpNew);
            
        }
        }
    }
    
    //Generating Grant number value
    List<outfunds__Funding_Request__c> FrListToUpdate = new List<outfunds__Funding_Request__c>();
    for(outfunds__Funding_Request__c fr: trigger.new){
        if(fr.Grant_Number__c == null){
            String hashString = '1000' + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));// I am getting todays date using the Datetime.now and formatting it in a certain format using formatGMT
            System.debug(hashString);
            Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(hashString)); // MD5 is an algorithm and pass the string.
            String hexDigest = EncodingUtil.convertToHex(hash);
            system.debug('##########' + hexDigest );
            outfunds__Funding_Request__c frNew = new outfunds__Funding_Request__c(Id = fr.Id);
            frNew.Grant_Number__c = hexDigest;
            FrListToUpdate.add(frNew);
        }
    }
    
    
            recordsToUpdate.addAll(fundingProgramMap.values());
            System.debug('updating records: ' + recordsToUpdate);    

    try{
        update recordsToUpdate;
        update FrListToUpdate;
    }catch(Exception e){
        System.debug('Error ==>' +e.getMessage());
    }
        
}