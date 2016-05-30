public with sharing class KnowledgeCategoryTriggerHandler extends TriggerHandler.DelegateBase  {
   //--------------------------------------------------------------------------
   	
   	//Create contract list
         List<Contract> contracts = new List <Contract>();
   	
   	public override void prepareBefore()
    {
        
    }

    public override void prepareAfter()
    {
        
    }

    //--------------------------------------------------------------------------
    // Before insert
    //--------------------------------------------------------------------------
    public override void beforeInsert(SObject o)
    {
    	
    }

    //--------------------------------------------------------------------------
    // After insert
    //--------------------------------------------------------------------------
    public override void afterInsert(SObject o)
    {
     
    }

    //--------------------------------------------------------------------------
    // Before update
    //--------------------------------------------------------------------------
    public override void beforeUpdate(SObject old, SObject o)
    {
    	
    }
    
    //--------------------------------------------------------------------------
    // After update
    //--------------------------------------------------------------------------
    public override void afterUpdate(SObject old, SObject o)
    {
    	//my custom function
            //if 
        
    }
 

    //--------------------------------------------------------------------------
    // Before delete
    //--------------------------------------------------------------------------
    public override void beforeDelete(SObject old)
    {
        

    }   

    //--------------------------------------------------------------------------
    // After delete
    //--------------------------------------------------------------------------
    public override void afterDelete(SObject old)
    {
        

    }

   
}