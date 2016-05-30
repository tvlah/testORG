public with sharing class TrainingCtrl {

public List<Contact> contList { get; set; }

    public TrainingCtrl(ApexPages.StandardController controller) {
            someText = 'Start text';
            accId = controller.getId();
            contList = [Select Id, Name, Email, Birthdate from Contact where AccountId = :accId];
            
            
    }

public Id accId { get; set; }
public string accId2 { get; set; }
public string someText {get; set; }
 
    
    public PageReference ourFirstACtion()
    {
        someText = 'New text';
        return null;
    }
    
    public PageReference saveCnt()
    {
        update contList;
        return null;
    }

@RemoteAction
    public static string fillCategories(List<Id> expandedCats, Id accountId)
    {
    
    return '';
    }

}