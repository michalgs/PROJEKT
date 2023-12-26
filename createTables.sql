USE ProjectDB

IF OBJECT_ID(N'dbo.Stadiums', N'U') IS NULL
CREATE TABLE Stadiums(
    StadiumID INT PRIMARY KEY,
    Stadium_Name VARCHAR(50) NOT NULL,
    City_Name VARCHAR(50) NOT NULL,
    [Address] VARCHAR(50) NOT NULL,
    Capacity INT NOT NULL
)
GO

IF OBJECT_ID(N'dbo.Teams', N'U') IS NULL
CREATE TABLE Teams(
    TeamID INT PRIMARY KEY,
    Team_Name VARCHAR(50) NOT NULL,
    StadiumID INT FOREIGN KEY REFERENCES Stadiums
)
GO

IF OBJECT_ID(N'dbo.Players', N'U') IS NULL
CREATE TABLE Players(
    PlayerID INT PRIMARY KEY,
    Player_Name VARCHAR(50) NOT NULL,
    Player_Surname VARCHAR(50) NOT NULL,
    TeamID INT FOREIGN KEY REFERENCES Teams
)
GO

IF OBJECT_ID(N'dbo.Coaches', N'U') IS NULL
CREATE TABLE Coaches(
    CoachID INT PRIMARY KEY,
    Coach_Name VARCHAR(50) NOT NULL,
    Coach_Surname VARCHAR(50) NOT NULL
)
GO