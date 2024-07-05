use bank;

/*objective question 2: Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year.*/
SELECT Surname, `YEAR`, EstimatedSalary 
FROM (SELECT
		Surname, 
		YEAR(Bank_DOJ) AS `YEAR`,
        EstimatedSalary, 
        DENSE_RANK() OVER(PARTITION BY YEAR(Bank_DOJ) ORDER BY EstimatedSalary DESC) AS rn FROM customer_info
        WHERE MONTH(Bank_DOJ) BETWEEN 10 AND 12) AS top_cus
WHERE rn<=5;

/*objective question 3: Calculate the average number of products used by customers who have a credit card.*/
SELECT AVG(NumofProducts) AS Num_of_products FROM bank_churn
WHERE Has_creditCard = 1 & Exited = 0;

/*objective question 4: Determine the churn rate by gender for the most recent year in the dataset.*/
WITH churn_rate AS(
	SELECT c.GenderID, COUNT(CASE WHEN b.Exited = 1 THEN b.CustomerId END) AS churned_customers,
	COUNT(b.CustomerId) AS total_customers
	FROM customer_info c 
	JOIN bank_churn b ON c.CustomerId = b.CustomerId
	WHERE YEAR(c.Bank_DOJ) = '2019'
	GROUP BY c.GenderID
)
SELECT 
	CASE 
		WHEN GenderID = 1 THEN ROUND((churned_customers / total_customers)*100, 2) END AS male_churn_rate,
	CASE 
		WHEN GenderID = 2 THEN ROUND((churned_customers / total_customers)*100, 2) END AS Female_churn_rate 
FROM churn_rate;

/*objective question 5: Compare the average credit score of customers who have exited and those who remain.*/
SELECT AVG(CASE WHEN Exited = 1 THEN CreditScore END) AS avg_creditScore_exited_customers,
	AVG(CASE WHEN Exited = 0 THEN CreditScore END) AS avg_creditScore_retained_customers
FROM bank_churn;

/*objective question 6: Which gender has a higher average estimated salary, and how does it relate to the number of active accounts?*/
SELECT g.GenderCategory, ROUND(AVG(c.EstimatedSalary), 2) AS EstimatedSalary, SUM(b.IsActiveMember) AS Active_accounts
FROM customer_info c
JOIN gender g ON c.GenderID = g.GenderID
JOIN bank_churn b ON c.CustomerID = b.CustomerID
WHERE b.IsActiveMember = 1
GROUP BY g.GenderCategory;  
/* Females have a higher average estimate salary but Males have more number of active accounts than females, 
here there is no direct relationship by these. */

/*objective question 7: Segment the customers based on their credit score and identify the segment with the highest exit rate. */
SELECT 
	CASE 
		WHEN CreditScore BETWEEN 800 AND 850 THEN 'Excellent'
		WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very_Good'
		WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
		WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair'
		WHEN CreditScore BETWEEN 300 AND 579 THEN 'Poor' 
	End as Cred_segments, 
COUNT(*) customer_count,
SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) AS exited_cust,
ROUND((SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS exit_rate
FROM bank_churn
GROUP BY Cred_segments
ORDER BY exit_rate DESC; #Highest Exit rate happends on the segment poor. 

/*objective question 8: Find out which geographic region has the highest number of active customers with a tenure greater than 5 years.*/
SELECT GeographyLocation, num_Active_customers FROM (SELECT g.GeographyLocation, COUNT(g.GeographyLocation) AS num_Active_customers,
DENSE_RANK() OVER(ORDER BY COUNT(g.GeographyLocation) DESC) AS rn
FROM customer_info c
JOIN bank_churn b ON c.CustomerID = b.CustomerID
JOIN geography g ON c.GeographyID = g.GeographyID
WHERE b.Tenure > 5 AND b.IsActiveMember = 1
GROUP BY g.GeographyLocation
) AS location
WHERE rn = 1;  #France (797) is the geographic region has the highest number of active customers with a tenure greater than 5 years. 

/*objective question 11: Examine the trend of customer joining over time and identify any seasonal patterns (yearly or monthly). 
	Prepare the data through SQL and then visualize it.*/
SELECT YEAR(Bank_DOJ) AS join_year,
MONTH(Bank_DOJ) AS join_month,
COUNT(CustomerID) AS num_of_customers
FROM customer_info
GROUP BY YEAR(Bank_DOJ), MONTH(Bank_DOJ)
ORDER BY YEAR(Bank_DOJ), MONTH(Bank_DOJ);

/*objective question 15: 
	Using SQL, write a query to find out the gender wise average income of male and female in each geography id. 
	Also rank the gender according to the average value.*/
SELECT c.GeographyID, g.GenderCategory, ROUND(AVG(c.EstimatedSalary), 2) AS EstimatedSalary,
RANK() OVER(PARTITION BY c.GeographyID ORDER BY ROUND(AVG(c.EstimatedSalary), 2) DESC, g.GenderCategory) AS `RANK`
FROM customer_info c
JOIN gender g ON c.GenderID = g.GenderID
GROUP BY c.GeographyID, g.GenderCategory;

/* objective question 16: Using SQL, write a query to find out the average tenure of the people who have exited in each 
	age bracket (18-30, 30-50, 50+).*/
SELECT 
	CASE 
		WHEN c.Age BETWEEN 18 AND 30 THEN '18-30'
		WHEN c.Age BETWEEN 30 AND 50 THEN '30-50'
		WHEN c.Age > 50 THEN '50+' End as age_bracket, ROUND(AVG(b.Tenure), 2) as avg_tenure_of_people_exited 
FROM customer_info c 
JOIN bank_churn b ON c.CustomerID = b.CustomerID
WHERE b.Exited = 1
Group by 
	CASE 
		WHEN c.Age BETWEEN 18 AND 30 THEN '18-30'
		WHEN c.Age BETWEEN 30 AND 50 THEN '30-50'
		WHEN c.Age > 50 THEN '50+' End
ORDER BY age_bracket;

/*objective question 19: Rank each bucket of credit score as per the number of customers who have churned the bank.*/
SELECT 
	CASE 
		WHEN CreditScore BETWEEN 800 AND 850 THEN 'Excellent'
		WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very_Good'
		WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
		WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair'
		WHEN CreditScore BETWEEN 300 AND 579 THEN 'Poor' 
	End as Cred_segments, 
COUNT(*) customer_count,
SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) AS exited_cust,
RANK() OVER(ORDER BY SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) DESC) AS `RANK`
FROM bank_churn
GROUP BY Cred_segments;

/*objective question 20: According to the age buckets find the number of customers who have a credit card. 
			Also retrieve those buckets who have lesser than average number of credit cards per bucket. */
SELECT 
	CASE 
		WHEN c.Age BETWEEN 18 AND 30 THEN '18-30'
		WHEN c.Age BETWEEN 30 AND 50 THEN '30-50'
		WHEN c.Age > 50 THEN '50+' End as age_bracket, COUNT(CASE WHEN b.Has_creditCard = 1 THEN b.CustomerID END) AS num_customers
FROM customer_info c 
JOIN bank_churn b ON c.CustomerID = b.CustomerID
Group by age_bracket
ORDER BY age_bracket; 
/* Second part of this question : Also retrieve those buckets who have lesser than average number of credit cards per bucket.*/

SELECT age_bracket, num_customers FROM (SELECT 
	CASE 
		WHEN c.Age BETWEEN 18 AND 30 THEN '18-30'
		WHEN c.Age BETWEEN 30 AND 50 THEN '30-50'
		WHEN c.Age > 50 THEN '50+' End as age_bracket, 
		COUNT(CASE WHEN b.Has_creditCard = 1 THEN b.CustomerID END) AS num_customers
FROM customer_info c 
JOIN bank_churn b ON c.CustomerID = b.CustomerID
Group by age_bracket
ORDER BY age_bracket) AS A
WHERE num_customers > (SELECT COUNT(Has_creditCard)/3 AS avg_credit_cust FROM bank_churn WHERE Has_creditCard = 1);

/*objective question 21: Rank the Locations as per the number of people who have churned the bank and average balance of the learners.*/
SELECT g.GeographyLocation, COUNT(b.Exited) AS churned_cus, ROUND(AVG(b.Balance), 2) AS avg_bal, 
RANK() OVER(ORDER BY COUNT(b.Exited) DESC, AVG(b.Balance)) AS `RANK` 
FROM customer_info c 
JOIN bank_churn b ON c.CustomerID = b.CustomerID
JOIN geography g ON c.GeographyID = g.GeographyID
WHERE b.Exited = 1
GROUP BY g.GeographyLocation;

/*objective question 22: As we can see that the “CustomerInfo” table has the CustomerID and Surname, 
	now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, 
    come up with a column where the format is “CustomerID_Surname”.*/
ALTER TABLE customer_info ADD COLUMN CustomerID_Surname VARCHAR(100) AS (CONCAT(CustomerID, '_', Surname));
SELECT * FROM customer_info;

#/*objective question 23: Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? */
SELECT b.*, e.ExitCategory FROM bank_churn b, exit_customer e
WHERE b.Exited = e.ExitID;

/*objective question 25: Write the query to get the customer ids, their last name and whether they are active or not for the 
customers whose surname  ends with “on”.*/
SELECT CustomerID, Surname FROM customer_info
WHERE RIGHT(LOWER(Surname), 2) LIKE '%on';


/*of Subjective question 9: Utilize SQL queries to segment customers based on demographics and account details.*/

/*Segment customer based on demographics age and account details*/
SELECT age_bracket, num_customers, Average_balance, Average_salary, 
		Average_CreditScore, Average_NumofProducts, churn_rate, retention_rate, credit_card_adop_rate, Active_members, Inactive_members, Average_Tenure FROM (SELECT 
	CASE 
		WHEN c.Age BETWEEN 18 AND 30 THEN '18-30'
		WHEN c.Age BETWEEN 30 AND 50 THEN '30-50'
		WHEN c.Age > 50 THEN '50+' End as age_bracket, 
		COUNT(CASE WHEN b.Has_creditCard = 1 THEN b.CustomerID END) AS num_customers,
        Round(AVG(b.Balance),0) AS Average_balance, 
        Round(AVG(c.EstimatedSalary),0) AS Average_salary,
        Round(AVG(b.CreditScore),0) AS Average_CreditScore,
        Round(AVG(b.NumofProducts),0) AS Average_NumofProducts,
        Round(AVG(b.Exited),3)*100 AS churn_rate,
        100-Round(AVG(b.Exited),3)*100 AS retention_rate,
        SUM(b.Has_creditcard)/count(Has_creditcard) *100 AS credit_card_adop_rate,
        SUM(b.IsActiveMember) AS Active_members,
        SUM(CASE WHEN b.IsActiveMember = 0 THEN 1 END) AS Inactive_members,
        Round(AVG(b.Tenure),1) AS Average_Tenure
FROM customer_info c 
JOIN bank_churn b ON c.CustomerID = b.CustomerID
Group by age_bracket
ORDER BY age_bracket) AS A
;

/*Segment customer based on demographics gender*/
SELECT GenderCategory, num_customers, Average_balance, Average_salary, 
		Average_CreditScore, Average_NumofProducts, churn_rate, retention_rate, credit_card_adop_rate, Active_members, Inactive_members, Average_Tenure FROM (SELECT 
	GenderCategory, 
		COUNT(CASE WHEN b.Has_creditCard = 1 THEN b.CustomerID END) AS num_customers,
        Round(AVG(b.Balance),0) AS Average_balance, 
        Round(AVG(c.EstimatedSalary),0) AS Average_salary,
        Round(AVG(b.CreditScore),0) AS Average_CreditScore,
        Round(AVG(b.NumofProducts),0) AS Average_NumofProducts,
        Round(AVG(b.Exited),3)*100 AS churn_rate,
        100-Round(AVG(b.Exited),3)*100 AS retention_rate,
        SUM(b.Has_creditcard)/count(Has_creditcard) *100 AS credit_card_adop_rate,
        SUM(b.IsActiveMember) AS Active_members,
        SUM(CASE WHEN b.IsActiveMember = 0 THEN 1 END) AS Inactive_members,
        Round(AVG(b.Tenure),1) AS Average_Tenure
FROM customer_info c 
JOIN bank_churn b ON c.CustomerID = b.CustomerID
JOIN gender g ON c.GenderID = g.GenderID
Group by GenderCategory) AS A
;

/*Segment customer based on demographics geography*/
SELECT GeographyLocation, num_customers, Average_balance, Average_salary, 
		Average_CreditScore, Average_NumofProducts, churn_rate, retention_rate, credit_card_adop_rate, Active_members, Inactive_members, Average_Tenure FROM (SELECT 
	GeographyLocation, 
		COUNT(CASE WHEN b.Has_creditCard = 1 THEN b.CustomerID END) AS num_customers,
        Round(AVG(b.Balance),0) AS Average_balance, 
        Round(AVG(c.EstimatedSalary),0) AS Average_salary,
        Round(AVG(b.CreditScore),0) AS Average_CreditScore,
        Round(AVG(b.NumofProducts),0) AS Average_NumofProducts,
        Round(AVG(b.Exited),3)*100 AS churn_rate,
        100-Round(AVG(b.Exited),3)*100 AS retention_rate,
        SUM(b.Has_creditcard)/count(Has_creditcard) *100 AS credit_card_adop_rate,
        SUM(b.IsActiveMember) AS Active_members,
        SUM(CASE WHEN b.IsActiveMember = 0 THEN 1 END) AS Inactive_members,
        Round(AVG(b.Tenure),1) AS Average_Tenure
FROM customer_info c 
JOIN bank_churn b ON c.CustomerID = b.CustomerID
JOIN geography g ON c.GeographyID = g.GeographyID
Group by GeographyLocation
ORDER BY num_customers DESC) AS A
;

/*Segment customers based on credit scores*/
SELECT 
	CASE 
		WHEN CreditScore BETWEEN 800 AND 850 THEN 'Excellent'
		WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very_Good'
		WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
		WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair'
		WHEN CreditScore BETWEEN 300 AND 579 THEN 'Poor' 
	End as Cred_segments, 
COUNT(*) customer_count
FROM bank_churn
GROUP BY Cred_segments;

/*Segment customers based on NumOfProducts*/
SELECT NumofProducts, 
COUNT(*) customer_count
FROM bank_churn
GROUP BY NumofProducts
Order by NumofProducts;

/*Segment customers based on IsActiveMember*/
SELECT SUM(IsActiveMember) AS Active_customers, 
	SUM(CASE 
			WHEN IsActiveMember = 0 THEN 1 
            END) AS Inactive_customers
FROM bank_churn;

/*Segment customers based on Has_creditCard*/
SELECT SUM(Has_creditCard) AS credit_card_holders, 
	SUM(CASE 
			WHEN Has_creditCard = 0 THEN 1 
            END) AS non_credit_card_holders
FROM bank_churn;

/*Segment customers based on Exited*/
SELECT SUM(Exited) AS churned_customers, 
	SUM(CASE 
			WHEN Exited = 0 THEN 1 
            END) AS retained_customers
FROM bank_churn;

/*Segment customers based on Tenure*/
SELECT Tenure, COUNT(CustomerId) AS num_customers
FROM bank_churn
GROUP BY Tenure
ORDER BY Tenure;

/*Subjective question 14: In the “Bank_Churn” table how can you modify the name of “HasCrCard” column to “Has_creditcard”?*/
ALTER TABLE bank_churn RENAME COLUMN HasCrCard TO Has_creditcard;
SELECT * FROM bank_churn;

