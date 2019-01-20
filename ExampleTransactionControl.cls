/*
 * Created by Silvio Altmann on 20.01.2019.
 *
 * Home » Developer Documentation » Apex Developer Guide » Transaction Control
 * 
 * Example methods to test limitations generating savepoint variables and rolling back the database
 * 
*/

public with sharing class ExampleTransactionControl {

    private static Account a = new Account(Name = 'New Account', AccountNumber = 'ExampleTransactionControl');

    public static void execute(Integer i) {

        if (i == 1) {
            rollbackOneSavePoint();
        } else if (i == 2) {
            rollbackTwoSavePointsValid();
        } else if (i == 3) {
            rollbackTwoSavePointsInvalid();
        } else if (i == 4) {
            rollbackIdNotCleared();
        }

        deleteExampleAccounts();
    }


    private static void rollbackOneSavePoint() {
        Savepoint sp1;

        insert a;
        debugAccount('insert a          ');

        sp1 = Database.setSavepoint();
        debugAccount('setSavepoint() sp1');

        a.Name = '1rst update Account';
        update a;
        debugAccount('update a          ');

        Database.rollback(sp1);
        debugAccount('1. rollback(sp1)  ');

        System.debug(Limits.getDmlRows());

        Database.rollback(sp1);
        debugAccount('2. rollback(sp1)  ');

        System.debug(Limits.getDmlRows());

        a.Name = '2nd update Account';
        update a;
        debugAccount('update a          ');

        Database.rollback(sp1);
        debugAccount('4. rollback(sp1)  ');

    }

    private static void rollbackTwoSavePointsValid() {

        Savepoint sp1;
        Savepoint sp2;

        insert a;
        debugAccount('insert a          ');

        sp1 = Database.setSavepoint();
        debugAccount('setSavepoint() sp1');

        a.Name = '1rst update Account';
        update a;
        debugAccount('update a          ');

        sp2 = Database.setSavepoint();
        debugAccount('setSavepoint() sp2');

        a.Name = '2nd update Account';
        update a;
        debugAccount('update a          ');

//if you rolled back to SP2,
        Database.rollback(sp2);
        debugAccount('1. rollback(sp2)  ');

//the variable SP1 would still be valid.
        Database.rollback(sp1);
        debugAccount('2. rollback(sp1)  ');
    }


    private static void rollbackTwoSavePointsInvalid() {
/*
        If you set more than one savepoint,
        then roll back to a savepoint that is not the last savepoint you generated,
        the later savepoint variables become invalid.

        For example, if you generated savepoint SP1 first,
        savepoint SP2 after that,
        and then you rolled back to SP1,
        the variable SP2 would no longer be valid.

        You will receive a runtime error if you try to use it.
*/

        Savepoint sp1;
        Savepoint sp2;

        insert a;
        debugAccount('insert a          ');

//For example, if you generated savepoint SP1 first,
        sp1 = Database.setSavepoint();
        debugAccount('setSavepoint() sp1');

        a.Name = '1rst update Account';
        update a;
        debugAccount('update a          ');

//savepoint SP2 after that,
        sp2 = Database.setSavepoint();
        debugAccount('setSavepoint() sp2');

        a.Name = '2nd update Account';
        update a;
        debugAccount('update a          ');

//and then you rolled back to SP1,
        Database.rollback(sp1);
        debugAccount('1. rollback(sp1)  ');

//the variable SP2 would no longer be valid.
        try {
            Database.rollback(sp2);
        } catch (Exception e) {
            System.debug('2. rollback(sp2)   - Exception=' + e.getMessage() + ' * DmlRows=' + Limits.getDmlRows());
        }
    }

    private static void rollbackIdNotCleared() {
/*
        The ID on an sObject inserted after setting a savepoint is not cleared after a rollback.
        Create an sObject to insert after a rollback.

        Attempting to insert the sObject using the variable created before the rollback fails
        because the sObject variable has an ID.

        Updating or upserting the sObject using the same variable also fails
        because the sObject is not in the database and, thus, cannot be updated.
*/

        Savepoint sp1;

        sp1 = Database.setSavepoint();
        debugAccount('setSavepoint() sp1');

        insert a;
        debugAccount('insert a          ');

        Database.rollback(sp1);
        debugAccount('1. rollback(sp1)  ');

        try {
            insert a;
        } catch (Exception e) {
            System.debug('insert a           - Exception=' + e.getMessage() + ' * DmlRows=' + Limits.getDmlRows());
        }
    }

    private static void debugAccount(String step) {
        Account[] debugAccounts = [SELECT Id, Name, AccountNumber FROM Account WHERE AccountNumber = 'ExampleTransactionControl' LIMIT 1];

        if (debugAccounts.isEmpty() == true) {
            System.debug(step + ' - No account in database (sObject Id=' + a.Id + ') * DmlRows=' + Limits.getDmlRows());
        } else {
            System.debug(step + ' - a.Name="' + debugAccounts[0].Name + '" (sObject Id=' + a.Id + ') * DmlRows=' + Limits.getDmlRows());
        }
    }

    private static void deleteExampleAccounts() {
        Account[] debugAccounts = [SELECT Id, Name, AccountNumber FROM Account WHERE AccountNumber = 'ExampleTransactionControl' LIMIT 1];
        System.debug('going to delete ' + debugAccounts.size() + ' example-account(s)');
        delete debugAccounts;

    }


}

