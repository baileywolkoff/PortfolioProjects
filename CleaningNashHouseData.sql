/* 
CLEANING IN SQL

Tasks (from exploring in excel):
- Need to reformat Date
- Serparate out city, state into own cells from address
- address null values in PropertyAddress
- create separate columns for month, day and year
- find and address duplicates (UniqueID, Names and Dates)
- SoldAsVacant column needs to be just Yes or No
*/


SELECT *
FROM PortfolioProject.dbo.NashHouse

-- Remove the Time from SaleDate Column
-- Convert to Date

Select SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashHouse;

ALTER TABLE NashHouse
ALTER COLUMN SaleDate date ;



-------- NULLS in PropertyAddress ------------

SELECT *
FROM PortfolioProject..NashHouse
WHERE PropertyAddress is null;

-- ParcelID is Unique to PropertyAddress, so we can use it to populate PropertyAddress (and vice-versa if it occurs)
-- Need to Self join to check for missing info in columns
SELECT nh1.ParcelID, nh1.PropertyAddress, nh2.ParcelID, nh2.PropertyAddress, ISNULL(nh1.PropertyAddress, nh2.PropertyAddress)
FROM PortfolioProject..NashHouse nh1
JOIN PortfolioProject..NashHouse  nh2
	ON nh1.ParcelID = nh2.ParcelID
	AND nh1.[UniqueID ] <> nh2.[UniqueID ] --UniqueID is unique to every row, so we dont want to join the same row
WHERE nh1.PropertyAddress is null;


-- update the table using the ISNULL() function
UPDATE nh1
SET PropertyAddress = ISNULL(nh1.PropertyAddress,nh2.PropertyAddress)
FROM PortfolioProject..NashHouse nh1
JOIN PortfolioProject..NashHouse  nh2
	ON nh1.ParcelID = nh2.ParcelID
	AND nh1.[UniqueID ] <> nh2.[UniqueID ]
WHERE nh1.PropertyAddress is null



------SPLITTING ADDRESS COLUMNS UP------

SELECT PropertyAddress, OwnerAddress
FROM PortfolioProject..NashHouse

-- Need to split between address, city and state by the ',' delimeter
-- Lets do the PropertyAddress first
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashHouse
ORDER BY City, Address

ALTER TABLE NashHouse
ADD PropertyAddressSplit nvarchar(255)

UPDATE NashHouse
SET PropertyAddressSplit = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashHouse
ADD PropertyCitySplit nvarchar(255)

UPDATE NashHouse
SET PropertyCitySplit = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

SELECT *
FROM NashHouse

-- Now lets do the owner address
SELECT OwnerAddress
FROM PortfolioProject..NashHouse


Select 
PARSENAME(REPLACE(OwnerAddress,',','.'), 1) --Takes the last group (State in this case)
FROM PortfolioProject..NashHouse

Select 
PARSENAME(REPLACE(OwnerAddress,',','.'), 3) AS Address
,PARSENAME(REPLACE(OwnerAddress,',','.'), 2) AS City
,PARSENAME(REPLACE(OwnerAddress,',','.'), 1) AS State
FROM PortfolioProject..NashHouse

--add columns, then update with values
ALTER TABLE NashHouse
ADD OwnerAddressSplit nvarchar(255)

UPDATE NashHouse
SET OwnerAddressSplit = PARSENAME(REPLACE(OwnerAddress,',','.'), 3)

ALTER TABLE NashHouse
ADD OwnerCitySplit nvarchar(255)

UPDATE NashHouse
SET OwnerCitySplit = PARSENAME(REPLACE(OwnerAddress,',','.'), 2)

ALTER TABLE NashHouse
ADD OwnerStateSplit nvarchar(255)

UPDATE NashHouse
SET OwnerStateSplit = PARSENAME(REPLACE(OwnerAddress,',','.'), 1)

SELECT *
FROM NashHouse



----------DUPLICATES---------------------


WITH RowNumCTE AS(
Select *
, ROW_NUMBER() OVER(
					PARTITION BY ParcelID,
								 PropertyAddress,
								 SalePrice,
								 SaleDate,
								 LegalReference
								 ORDER BY UniqueID
								 ) AS row_num
FROM PortfolioProject..NashHouse
)
SELECT * -- Change to delete if we want to remove Table
FROM RowNumCTE
WHERE row_num > 1 
ORDER BY ParcelID




-- Separate method
WITH DuplicateCTE AS
(
SELECT ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference
FROM PortfolioProject..NashHouse
GROUP BY ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference
HAVING COUNT(*) > 1
)

SELECT a.*
FROM PortfolioProject..NashHouse a
JOIN DuplicateCTE b
	ON a.ParcelID = b.ParcelID
	AND a.PropertyAddress = b.PropertyAddress
	AND a.SaleDate = b.SaleDate
	AND a.SalePrice = b.SalePrice
	AND a.LegalReference = b.LegalReference
ORDER BY a.ParcelID



-------- FIXING INCONSISTENT ENTIRES IN SoldAsVacant--------------

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS Count
FROM PortfolioProject..NashHouse
GROUP BY SoldAsVacant
ORDER BY 2

-- Because we can see that 'Y' and 'N' less frequent, we should change those values to match
-- Use a CASE statement
SELECT SoldAsVacant
, CASE WHEN SoldAsVacant='Y' THEN 'Yes'
	   WHEN SoldAsVacant='N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM PortfolioProject..NashHouse
WHERE SoldAsVacant in ('N','Y')

UPDATE NashHouse
SET SoldAsVacant = CASE 
					WHEN SoldAsVacant='Y' THEN 'Yes'
					WHEN SoldAsVacant='N' THEN 'No'
					ELSE SoldAsVacant
					END


-------DELETING UNUSED COLUMNS------------
--Shouldn't be done on the raw table, but will demonstrate how to here

ALTER TABLE PortfolioProject..NashHouse
DROP COLUMN PropertyAddress, OwnerAddress

SELECT *
FROM PortfolioProject..NashHouse
