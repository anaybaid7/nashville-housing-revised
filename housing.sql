-- Standardize date format
ALTER TABLE HousingData..NashvilleHousing
ADD SalesDate Date;

UPDATE HousingData..NashvilleHousing
SET SalesDate = CONVERT(Date, SaleDate)

-- Populate Property Address Data
UPDATE HousingData..NashvilleHousing
SET PropertyAddress = 
    (SELECT b.PropertyAddress
    FROM HousingData..NashvilleHousing b
    WHERE a.ParcelID = b.ParcelID
    AND b.PropertyAddress IS NOT NULL
    AND a.UniqueID <> b.UniqueID
    LIMIT 1)
WHERE a.PropertyAddress IS NULL;

-- Breaking PorpertyAddress and OwnerAddress into Address, City and State
ALTER TABLE HousingData..NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE HousingData..NashvilleHousing
SET PropertySplitAddress = split_part(PropertyAddress, ',', 1);

ALTER TABLE HousingData..NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE HousingData..NashvilleHousing
SET PropertySplitCity = split_part(PropertyAddress, ',', 2);

ALTER TABLE HousingData..NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

UPDATE HousingData..NashvilleHousing
SET OwnerSplitAddress = split_part(OwnerAddress, ',', 3);

ALTER TABLE HousingData..NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

UPDATE HousingData..NashvilleHousing
SET OwnerSplitCity = split_part(OwnerAddress, ',', 2);
	
ALTER TABLE HousingData..NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE HousingData..NashvilleHousing
SET OwnerSplitState = split_part(OwnerAddress, ',', 1);

-- Adding a new column for Bedrooms and Bathrooms
ALTER TABLE HousingData..NashvilleHousing
ADD Bathrooms INT;

-- Populate the new columns using substring
UPDATE HousingData..NashvilleHousing
SET Bedrooms = CAST(SUBSTRING(Rooms, 1, CHARINDEX('-', Rooms) - 1) AS INT);

UPDATE HousingData..NashvilleHousing
SET Bathrooms = CAST(SUBSTRING(Rooms, CHARINDEX('-', Rooms) + 1, LEN(Rooms)) AS INT);

-- Change values Y and N in SoldAsVacant to Yes and No respectively
UPDATE HousingData..NashvilleHousing
SET SoldAsVacant = 
    CASE SoldAsVacant
    WHEN 'Y' THEN 'Yes'
    WHEN 'N' THEN 'No'
    END;

-- Adding a new column for the city and state code
ALTER TABLE HousingData..NashvilleHousing
ADD CityCode INT;

ALTER TABLE HousingData..NashvilleHousing
ADD StateCode INT;

-- Populate the new columns using city and state name
UPDATE HousingData..NashvilleHousing
SET CityCode = (SELECT CityCode FROM ref_cities WHERE CityName = PropertySplitCity);

UPDATE HousingData..NashvilleHousing
SET StateCode = (SELECT StateCode FROM ref_states WHERE StateName = OwnerSplitState);

-- Adding an index on SaleDate, ParcelID and UniqueID
CREATE INDEX SaleDate_IDX ON HousingData..NashvilleHousing (SaleDate);
CREATE INDEX ParcelID_IDX ON HousingData..NashvilleHousing (ParcelID);
CREATE INDEX UniqueID_IDX ON HousingData..NashvilleHousing (UniqueID);

-- Selecting only necessary columns with parameterized queries
DECLARE @startDate DATE, @endDate DATE;
SET @startDate = '2022-01-01';
SET @endDate = '2022-12-31';

SELECT UniqueID, SalesDate, PropertySplitAddress, PropertySplitCity, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState, SoldAsVacant,Bedrooms, Bathrooms, CityCode, StateCode
FROM HousingData..NashvilleHousing 
WHERE SalesDate BETWEEN @startDate and @endDate;

-- Adding a new column for Zipcode
ALTER TABLE HousingData..NashvilleHousing
ADD Zipcode INT;

-- Populate the new column using substring and cross-reference with a zipcode table 
UPDATE HousingData..NashvilleHousing
SET Zipcode = (SELECT Zipcode FROM ref_zipcodes WHERE CityCode = NashvilleHousing.CityCode AND StateCode = NashvilleHousing.StateCode);

-- Adding a new column for price per sqft
ALTER TABLE HousingData..NashvilleHousing
ADD PricePerSqft DECIMAL(18,2);

-- Populate the new column by calculating price per sqft 
UPDATE HousingData..NashvilleHousing
SET PricePerSqft = SalePrice/LivingArea;

-- Adding a new column for building type
ALTER TABLE HousingData..NashvilleHousing
ADD BuildingType nvarchar(255);

-- Populate the new column using a case statement
UPDATE HousingData..NashvilleHousing
SET BuildingType = 
    CASE 
    WHEN LivingArea <= 1000 THEN 'Condo'
    WHEN LivingArea BETWEEN 1001 AND 2000 THEN 'Townhouse'
    WHEN LivingArea BETWEEN 2001 AND 3000 THEN 'Single Family'
    WHEN LivingArea >= 3001 THEN 'Luxury Home'
    END;

-- Adding a new column for a calculated age of the building
ALTER TABLE HousingData..NashvilleHousing
ADD BuildingAge INT;

-- Populate the new column by using SaleDate and YearBuilt columns
UPDATE HousingData..NashvilleHousing
SET BuildingAge = DATEPART(YEAR, SalesDate) - YearBuilt;

-- Selecting all columns and ordering them by SalePrice
SELECT *
FROM HousingData..NashvilleHousing
ORDER BY SalePrice DESC;

-- Creating a temporary table to store the data grouped by City and State
CREATE TEMPORARY TABLE HousingData..CityStateSummary(
    City nvarchar(255), 
    State nvarchar(255), 
    TotalHomes INT, 
    TotalSalePrice DECIMAL(18,2),
    AvgPricePerSqft DECIMAL(18,2)
);

-- Populating the temporary table with data from NashvilleHousing table
INSERT INTO HousingData..CityStateSummary
SELECT PropertySplitCity, OwnerSplitState, COUNT(UniqueID), SUM(SalePrice), AVG(PricePerSqft)
FROM HousingData..NashvilleHousing
GROUP BY PropertySplitCity, OwnerSplitState;

-- Creating a stored procedure that takes a city and state as input
-- and returns the data from CityStateSummary table
CREATE PROCEDURE GetCityStateSummary(@City nvarchar(255), @State nvarchar(255))
AS
BEGIN
    SELECT City, State, TotalHomes, TotalSalePrice, AvgPricePerSqft
    FROM HousingData..CityStateSummary
    WHERE City = @City AND State = @State;
END
