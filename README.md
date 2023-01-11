# nashville-housing-revised
This SQL script is used to process and clean housing data for the Nashville area. The script is designed to be run on a SQL database with a table called "HousingData..NashvilleHousing" that contains the housing data.
Prerequisites: 
* SQL Server or equivalent database management system
* Table named 'HousingData..NashvilleHousing' with the necessary columns
* A primary key defined for table NashvilleHousing
Functionality: 
The script performs the following operations:
* standardises the format of the "SaleDate" column and adds a new "SalesDate" column
* populates a "PropertyAddress" column by using the "ParcelID" column
* breaks up the "PropertyAddress" and "OwnerAddress" columns into multiple columns containing address, city, and state information
* changes the values in the "SoldAsVacant" column from "Y" and "N" to "Yes" and "No" respectively.
* Selecting only necessary columns
Additional Features: 
* Adding a new column for Zipcode and populating it using a cross-reference with a Zipcode table
* Adding a new column for price per square foot, and calculate it by dividing SalePrice by LivingArea
* Adding a new column for building type, it's calculated by a case statement based on LivingArea
* Adding a new column for the building age and calculating it by using SaleDate and YearBuilt
* Selecting all columns and ordering them by SalePrice in descending order
* Please note that the ref_zipcodes, ref_cities and ref_states should exist in your database. Also, make sure to adjust the column names and table names to match your actual database.

