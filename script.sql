-- lab 8;
use salemanagement;
-- 1. Create a trigger before_total_quantity_update to update total quantity of product when 
-- Quantity_On_Hand and Quantity_sell change values. Then Update total quantity when Product P1004 
-- have Quantity_On_Hand = 30, quantity_sell =35.
DELIMITER $$

CREATE TRIGGER before_total_quantity_update
BEFORE UPDATE ON product
FOR EACH ROW
BEGIN
    SET NEW.total_quantity = NEW.Quantity_On_Hand + NEW.Quantity_sell;
END$$

DELIMITER ;
update product
set Quantity_On_Hand = 30, Quantity_Sell=35
where Product_Number="P1004";
-- 2. Create a trigger before_remark_salesman_update to update Percentage of per_remarks in a salesman 
-- table (will be stored in PER_MARKS column) : per_remarks = target_achieved*100/sales_target.
alter table salesman
add column per_marks decimal(15,2);
update salesman
set per_marks = (Target_Achieved*100)/Sales_Target
where Salesman_Number is not null;
delimiter $$
create trigger before_remark_salesman_update
before update on salesman
for each row
begin
set new.per_marks = new.Target_Achieved*100/new.Sales_Target;
end$$
delimiter ;
SET SQL_SAFE_UPDATES = 0;
UPDATE salesman
SET Target_Achieved=110
WHERE Salesman_Number='S007';
select * from salesman;
-- 3. Create a trigger before_product_insert to insert a product in product table. 
delimiter $$
create trigger  before_product_insert
before insert on product
FOR EACH ROW
begin

end$$
delimiter ;
-- 4. Create a trigger to before update the delivery status to "Delivered" when an order is marked as 
-- "Successful".
delimiter $$
create trigger before_update_deliveryStatus
before update on salesorder
for each row
begin
if NEW.Order_Status = "Successful" then
set NEW.Delivery_Status = "Delivered";
end if;
end$$
delimiter ; 
update salesorder
set Order_Status = "Successful"
where Order_Number = "O20002";
-- 5. Create a trigger to update the remarks "Good" when a new salesman is insert
SELECT * FROM SALESMAN
delimiter $$
create trigger before_insert_salesman
before insert on salesman
for each row
begin
set new.remarks = 'Good';
end$$
delimiter ; 
insert into salesman(Salesman_Number,Salesman_Name,Address,City,Pincode,Province,Salary,Sales_Target,Target_Achieved,Phone) 
value('S009','Hoa','Hoa Phu','Thu Dau Mot',700053,'Binh Duong',13500,50,75,'0998213651');
-- 6. Create a trigger to enforce that the first digit of the pin code in the "Clients" table must be 7. 
delimiter $$
create trigger force_first_digit
before insert on clients
for each row
begin
if new.Pincode not like '7%'
then set new.Pincode = concat('7', SUBSTRING(NEW.Pincode, 2));
end if;
end$$
delimiter ;
insert into clients(Client_Number,Client_Name,Address,City,Pincode,Province,Amount_Paid,Amount_Due)
 value ('C111','Tran Ngoc','Phu My','Hanoi',800007,'Hanoi',9000,1000);
-- 7. Create a trigger to update the city for a specific client to "Unknown" when the client is deleted 
create table clientsDeleted(
Client_Number varchar(10),
Client_Name varchar(25) not null,
Address varchar(30),
City varchar(30),
Pincode int not null,
Province char(25),
Amount_Paid decimal (15,4),
Amount_Due decimal(15,4),
check(Client_Number like 'C%'),
primary key (Client_Number)
)
delimiter $$
create trigger update_city_when_delete
before delete on clients
for each row
begin
INSERT INTO clientsdeleted
VALUES(OLD.Client_Number,old.Client_Name, old.Address, 'Unknown',old.Pincode,old.Province,old.Amount_Paid,old.Amount_Due);
end$$
delimiter ;
delete from clients where Client_Number= "C111";
select * from clientsdeleted;
-- 8. Create a trigger after_product_insert to insert a product and update profit and total_quantity in product 
-- table.
alter table product
add column profit int;
alter table product
add column total_quantity int;
update product
set profit = (Quantity_Sell*Sell_Price) - (Cost_Price*total_quantity);
set sql_safe_updates = 0;
delimiter $$
create trigger after_product_insert
before insert on product
for each row
begin
set new.total_quantity = new.Quantity_Sell + new.Quantity_On_Hand, 
new.profit = (new.Quantity_Sell*new.Sell_Price) - (new.Cost_Price*new.total_quantity);
end$$
delimiter ; 
drop trigger after_product_insert;
insert into product(Product_Number,Product_Name,Quantity_On_Hand,Quantity_Sell,Sell_Price,Cost_Price,total_quantity,profit) 
value ('P1011','Banana18',10,30,1001,801,0,0);
select * from product;
-- 9. Create a trigger to update the delivery status to "On Way" for a specific order when an order is inserted. 
DELIMITER $$
CREATE TRIGGER update_delivery_status
before INSERT ON salesorder
FOR EACH ROW
BEGIN
SET new.Delivery_Status = 'On Way';
END$$
DELIMITER ;
INSERT INTO salesorder (Order_Number,Order_Date,Client_Number,Salesman_Number,Delivery_Status,Delivery_Date,Order_Status)
value ('O20017','2022-05-13','C108','S007','On Way', '2022-05-15','Successful');
select * from salesorder;
-- 10. Create a trigger before_remark_salesman_update to update Percentage of per_remarks in a salesman 
-- table (will be stored in PER_MARKS column)  If  per_remarks >= 75%, his remarks should be ‘Good’. 
-- If 50% <= per_remarks < 75%, he is labeled as 'Average'. If per_remarks <50%, he is considered 
-- 'Poor'.
delimiter $$
create trigger before_remark_salesman_update2
before update on salesman
for each row
begin
if new.per_marks >= 75 then set new.remarks = 'Good';
elseif new.per_marks < 75 and new.per_marks>=50 then set new.remarks = 'Average';
else set new.remarks = 'Poor';
end if;
end$$
delimiter ;
update salesman
set Sales_Target = 100,Target_Achieved = 50
where Salesman_Number = 'S009';
-- 11. Create a trigger to check if the delivery date is greater than the order date, if not, do not insert it. 
delimiter $$
create trigger check_deli_date
before insert on salesorder
for each row
begin
    if NEW.Delivery_Date <= NEW.Order_Date then
        signal sqlstate '45000' set message_text = 'Delivery date must be greater than order date.';
    end if;
end$$
delimiter ;
insert into salesorder value ('O20018','2022-05-15','C108','S007','On Way', '2022-05-12','Successful');
-- 12. Create a trigger to update Quantity_On_Hand when ordering a product (Order_Quantity). 
delimiter $$
create trigger update_quantity_on_hand
after insert on salesorderdetails
for each row
begin
    update product p
    join salesorderdetails s on p.Product_Number = s.Product_Number
    set p.Quantity_On_Hand = p.Quantity_On_Hand - s.Order_Quality
    where s.Order_Number = new.Order_Number;
end$$
delimiter ;
-- the old quantity of cucumber is 10, after insert it will be 4
insert into salesorderdetails value ('O20017','P1009',6);
select * from salesorderdetails;
select * from product;
-- Function
-- 1. Find the average salesman’s salary. 
select * from salesman;
delimiter $$
create function get_avg_salesman_salary()
returns decimal
deterministic
begin
 DECLARE avg_salary DECIMAL(10,2);
    SELECT AVG(Salary) INTO avg_salary
    FROM salesman;
    RETURN avg_salary;
end$$
delimiter ;
SELECT get_avg_salesman_salary() AS average_salesman_salary;
-- 2. Find the name of the highest paid salesman. 
delimiter $$
create function getHighestName()
returns varchar(15)
deterministic
begin
declare resultName varchar(15);
select group_concat(Salesman_Name separator ',') into resultName
from salesman
where Salary = (select max(Salary) from salesman);
return resultName;
end$$
delimiter ;
select * from salesman;
SELECT getHighestName() AS nameResult;
-- 3. Find the name of the salesman who is paid the lowest salary. 
delimiter $$
create function getLowestName()
returns varchar(500)
deterministic
begin
declare resultName varchar(500);
select group_concat(Salesman_Name separator ',') into resultName
from salesman
where Salary = (select min(Salary) from salesman);
return resultName;
end$$
delimiter ;
drop function getLowestName;
SELECT getLowestName() AS nameResult;
-- 4. Determine the total number of salespeople employed by the company. 
delimiter $$
create function get_total_salesman()
returns int
deterministic
begin
declare total_salesman int;
select count(Salesman_Number) into total_salesman
from salesman;
return total_salesman;
end$$
delimiter ;
select get_total_salesman() as totalSalesman;
select * from salesman;
-- 5. Compute the total salary paid to the company's salesman. 
delimiter $$
create function get_total_salary()
returns int
deterministic
begin
declare total_salary int;
select sum(Salary) into total_salary
from salesman;
return total_salary;
end$$
delimiter ;
select get_total_salary() as total_salary;
-- 6. Find Clients in a Province 
delimiter $$
CREATE FUNCTION find_clients_by_province(p_province VARCHAR(50))
RETURNS VARCHAR(500)
DETERMINISTIC
BEGIN
    DECLARE client_list VARCHAR(500);
    
    SELECT GROUP_CONCAT(Client_Name SEPARATOR ', ') INTO client_list
    FROM clients
    WHERE Province = p_province;
    
    RETURN client_list;
END$$
delimiter ;
select find_clients_by_province('Binh Duong') as listResult;
-- 7. Calculate Total Sales 
delimiter $$
create function cal_total_sales()
returns int
deterministic
begin
declare result int;
select count(Order_Number) into result
from salesorder;
return result;
end$$
delimiter ;
select cal_total_sales() as result;
select * from salesorder;
-- 8. Calculate Total Order Amount 
delimiter $$
create function cal_total_order_amount()
returns int
deterministic
begin
declare result int;
with A as (select sod.Order_Number, sod.Product_Number, (p.Sell_Price*sod.Order_Quality) as total_amt
from salesorderdetails sod join product p on p.Product_Number = sod.Product_Number)
select sum( total_amt ) into result from A;
return result;
end$$
delimiter ;
select cal_total_order_amount() as totalAmount;
