public without sharing class TriggerHandler 
{

	public interface Delegate 
	{
		void prepareBefore();
		void prepareAfter();
		
		void beforeInsert(sObject o);
		void beforeUpdate(sObject old, sObject o);
		void beforeDelete(sObject o);
		
		void afterInsert(sObject o);
		void afterUpdate(sObject old, sObject o);
		void afterDelete(sObject o);
		void afterUndelete(sObject o);
		
		void finish();
	}
	 
	public abstract class DelegateBase implements Delegate 
	{
		
		public virtual void prepareBefore() {}
		public virtual void prepareAfter() {}
		
		public virtual void beforeInsert(sObject o) {}
		public virtual void beforeUpdate(sObject old, sObject o) {}
		public virtual void beforeDelete(sObject o) {}
		
		public virtual void afterInsert(sObject o) {}
		public virtual void afterUpdate(sObject old, sObject o) {}
		public virtual void afterDelete(sObject o) {}
		public virtual void afterUndelete(sObject o) {}
		
		public virtual void finish() {}

	}
	
	public static void execute(Delegate d) 
	{
		No_Triggers__c notriggers = No_Triggers__c.getInstance(UserInfo.getUserId());
    
    	if (notriggers == null || !notriggers.Flag__c) 
    	{
		
			if (Trigger.isBefore) 
			{
				d.prepareBefore();
				
				if (Trigger.isInsert) 
				{
					for (sObject o : Trigger.new) 
					{
						d.beforeInsert(o);
					}
				} 
				else if (Trigger.isUpdate) 
				{
					for (sObject o : Trigger.old) 
					{
						d.beforeUpdate(o, Trigger.newMap.get(o.id));
					}
				} 
				else if (Trigger.isDelete) 
				{
					for (sObject o : Trigger.old) 
					{
						d.beforeDelete(o);
					}
				}
			} 
			else 
			{
				d.prepareAfter();
				
				if (Trigger.isInsert) 
				{
					for (sObject o : Trigger.new) 
					{
						d.afterInsert(o);
					}
				} 
				else if (Trigger.isUpdate) 
				{
					for (sObject o : Trigger.old) 
					{
						d.afterUpdate(o, Trigger.newMap.get(o.id));
					}
				} 
				else if (Trigger.isDelete) 
				{
					for (sObject o : Trigger.old) 
					{
						d.afterDelete(o);
					}
				}
			}
			
			d.finish();
		}
	}
}