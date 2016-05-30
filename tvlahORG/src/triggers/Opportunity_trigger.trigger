trigger Opportunity_trigger on Opportunity (after update, after insert) {
    
    List<Contract> contracts = new List<Contract>();
    
    for (Opportunity Opp : Trigger.new )
    {
        if (Opp.StageName == 'Closed Won' && (Trigger.IsInsert || !Trigger.oldMap.get(Opp.Id).isClosed)) {
            contracts.add(New Contract (AccountId = Opp.AccountId, Owner = Opp.Owner, Name = Opp.Name));
        }
    }
    if (!contracts.isEmpty()) {
        insert contracts;
    }
}