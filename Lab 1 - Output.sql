#1. Find how many members of the staff hold each working position.

SELECT s.position, COUNT(s.position)
FROM STAFF AS s
GROUP BY s.position;

#2. Find how many flats are available to rent in each city.

SELECT p.city, COUNT(p.city)
FROM PROPERTY_FOR_RENT AS p
GROUP BY p.city;

#3. Find how many properties are assigned to each branch.

SELECT b.branchNo, COUNT(p.branchNo)
FROM BRANCH AS b
JOIN PROPERTY_FOR_RENT AS p
    ON b.branchNo = p.branchNo
GROUP BY p.branchNo;

#4. Find the staff member assigned to properties located in Glasgow.

SELECT DISTINCT s.fName, s.lName
FROM STAFF AS s
JOIN PROPERTY_FOR_RENT AS p
    ON s.staffNo = p.staffNo
WHERE p.city = 'Glasgow';

#5. Find the properties viewed by the client Mary Tregear.

SELECT v.propertyNo
FROM VIEWING AS v
JOIN CLIENT AS c
    ON v.clientNo = c.clientNo
WHERE c.fName = 'Mary' AND c.lName = 'Tregear';

#6. Find the owner of Glasgow properties of type house.

SELECT p.fName, p.lName
FROM PRIVATE_OWNER AS p
WHERE p.address LIKE '%Glasgow%';


#7. Find the cities with more than two properties.

SELECT p.city
FROM PROPERTY_FOR_RENT AS p
GROUP BY p.city
HAVING COUNT(*) > 2;

#8. Find the branches with more than one assistant staff.

SELECT s.branchNo
FROM STAFF AS s
WHERE s.position = 'Assistant'
GROUP BY s.branchNo
HAVING COUNT(*) > 1;