# Customer Churn Prediction Feature Analysis (E-commerce)
Churn is one of the biggest problems in the E-commerce industry. The project firstly retrieves data using PostgreSQL and export all those features in CSV format. And then using Deep Learning Models to make churn prediction. The dataset contains every person who made a purchase either from Department 1, 2 or 3, in other words, the dataset is the User Portrait

### The project is inspired by the project called 'Telecom Churn prediction' from Kaggle
<b>Kaggle Link</b>: <a href=https://www.kaggle.com/bandiatindra/telecom-churn-prediction/comments>Telecom Churn Prediction</a>

### Dataset Description
The following descriptions of the 10 variables in the dataset are taken
from database using PostgreSQL:
<ol>
<li><b>supervision_total</b>: Date format float --> Total Sales from Department 1, aka supervision department </li>
<li><b>blackcard_total</b>: Date format float --> Total Sales from Department 2, aka blackcard department </li>
<li><b>ecommerce_total</b>: Date format float --> Total Sales from Department 3, aka ecommerce department </li>
<li><b>order_count</b>: Date format integer --> number of order for each customer </li>
<li><b>total_price</b>: Date format float --> Sum of total sales from department 1,2 and 3 </li>
<li><b>city_id</b>: Date format float --> ID for each city, For instance, Beijing corresponds to 0101, Shanghai corresponds to  </li>0201
<li><b>gender</b>: Date format integer --> 1: Male 2: Female </li>
<li><b>refund_fee</b>: Date format float --> Total Refund Fees from Department 1,2 and 3</li>
<li><b>last_buytime</b>: Date format integer --> KEY FEATURE: The most recent purchase time, this feature decides wheather churn or not directly </li>
<li><b>churn</b>: (Dependent Variable) Date format integer --> Given that most recent purchase is after 2020-5-1, the user is not considerd as churn user, otherwise the churn returns 1 </li>
</ol>

### Data Preparation
Stored Procedure usging PostgreSQL, the data of this table is originated from various tables in the database
* uid,user_id to locate each user
* addtime stands for the time for the user to be added into database
* jianli_totalprice,heika_totalprice,tuangou_totalprice are sales from different department
* min_buy_time: the earliest time to make a purchase 
* max_but_time: the latest time to make a purchase
* order_count is number of orders for each person
* total_price is the total amount of purchase each person made


  ```sql
  CREATE TABLE gathers_users 
  AS 
  SELECT uid,user_id,MIN(addtime) AS addtime,
  SUM(CASE WHEN leixing=1 THEN total_price ELSE 0 END) AS jianli_totalprice,
  SUM(CASE WHEN leixing=2 THEN total_price ELSE 0 END) AS heika_totalprice,
  SUM(CASE WHEN leixing=3 THEN total_price ELSE 0 END) AS tuangou_totalprice,
  MIN(min_buy_time) AS min_buy_time,
  MAX(max_buy_time) AS max_buy_time,
  SUM(order_count) AS order_count,
  SUM(total_price) AS total_price
  ```
  * City name and city ID are description of city
  * full_name is the name for each customer
  * gender 1:Male 2:Female
  * refund_fee is the sum of refund fee from Department 1,2 & 3
  * Churn is decided by the max_buy_time, if it is after 2020-5-1, then churn will be 0, else it will be 1.
  
  ```sql
  ALTER TABLE gathers_users ADD city_name VARCHAR(30) DEFAULT '';
  ALTER TABLE gathers_users ADD city_id VARCHAR(10) DEFAULT ''; 
  ALTER TABLE gathers_users ADD full_name VARCHAR(50) DEFAULT ''; 
  ALTER TABLE gathers_users ADD gender int DEFAULT NULL;
  ALTER TABLE gathers_users ADD refund_fee int DEFAULT 0; 
  ALTER TABLE gathers_users ADD churn int DEFAULT 0; 
  ```
