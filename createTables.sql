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
    StadiumID INT FOREIGN KEY REFERENCES Stadiums(StadiumID)
)
GO

IF OBJECT_ID(N'dbo.LeagueTable', N'U') IS NULL
CREATE TABLE LeagueTable(
   TeamID INT PRIMARY KEY,
   Matches INT DEFAULT 0,
   Points INT DEFAULT 0,
   GoalsScored INT DEFAULT 0,
   GoalsConceded INT DEFAULT 0
)
GO

IF OBJECT_ID(N'dbo.Players', N'U') IS NULL
CREATE TABLE Players(
    PlayerID INT PRIMARY KEY,
    Player_Name VARCHAR(50) NOT NULL,
    Player_Surname VARCHAR(50) NOT NULL,
    Player_Nationality VARCHAR(3) NOT NULL,
    Player_Birthdate DATE,
    Player_Position VARCHAR(3) NOT NULL, 
    TeamID INT FOREIGN KEY REFERENCES Teams(TeamID)
)
GO

IF OBJECT_ID(N'dbo.Coaches', N'U') IS NULL
CREATE TABLE Coaches(
    CoachID INT PRIMARY KEY,
    Coach_Name VARCHAR(50) NOT NULL,
    Coach_Surname VARCHAR(50) NOT NULL
)
GO

IF OBJECT_ID(N'dbo.Referees', N'U') IS NULL
CREATE TABLE Referees(
    RefereeID INT PRIMARY KEY,
    Referee_Name VARCHAR(50) NOT NULL,
    Referee_Surname VARCHAR(50) NOT NULL,
    Yellow_Cards_Given INT DEFAULT 0,
    Red_Cards_Given INT DEFAULT 0,
    Matches_Refereed INT DEFAULT 0
)
GO

IF OBJECT_ID(N'dbo.Matches', N'U') IS NULL
CREATE TABLE Matches(
    MatchID INT PRIMARY KEY,
    Match_Date DATE NOT NULL,
    FirstTeam INT FOREIGN KEY REFERENCES Teams(TeamID),
    SecondTeam INT FOREIGN KEY REFERENCES Teams(TeamID),
    FirstTeamScore INT,
    SecondTeamScore INT,
    RefereeID INT FOREIGN KEY REFERENCES Referees(RefereeID),
    Is_Confirmed BIT,
)


GO

IF OBJECT_ID(N'dbo.LeagueMatches', N'U') IS NULL
CREATE TABLE LeagueMatches(
   MatchID INT PRIMARY KEY,
   HostID INT FOREIGN KEY REFERENCES Teams(TeamID),
   Matchweek INT NOT NULL,
   Round CHAR CHECK (Round = 'W' OR Round = 'J'), -- runda wiosenna albo jesienna
   FOREIGN KEY (MatchID) REFERENCES Matches(MatchID)
)
GO

IF OBJECT_ID(N'dbo.PolishCupMatches', N'U') IS NULL
CREATE TABLE PolishCupMatches (
   MatchID INT PRIMARY KEY, 
   StadiumID INT FOREIGN KEY REFERENCES Stadiums(StadiumID),
   PlayOff_Round VARCHAR(10) NOT NULL,
   FOREIGN KEY (MatchID) REFERENCES Matches(MatchID) 
)
GO

IF OBJECT_ID(N'dbo.MatchesPlayers', N'U') IS NULL
CREATE TABLE MatchesPlayers(
    MatchID INT FOREIGN KEY REFERENCES Matches(MatchID),
    PlayerID INT FOREIGN KEY REFERENCES Players(PlayerID),
    Goals_Scored INT,
    Yellow_Cards INT CHECK (Yellow_Cards BETWEEN 0 AND 2),
    Red_Cards INT CHECK (Red_Cards BETWEEN 0 AND 1),
    PRIMARY KEY(MatchID, PlayerID)
)
GO

IF OBJECT_ID(N'dbo.CoachTeam', N'U') IS NULL
CREATE TABLE CoachTeam(
   CoachID INT FOREIGN KEY REFERENCES Coaches(CoachID),
   TeamID INT FOREIGN KEY REFERENCES Teams(TeamID),
   Start_Work DATE NOT NULL,
   End_Work DATE,
   PRIMARY KEY(CoachID, TeamID)
)
GO

IF OBJECT_ID(N'dbo.PlayerTeam', N'U') IS NULL
CREATE TABLE PlayerTeam (
   PlayerID INT FOREIGN KEY REFERENCES Players(PlayerID),
   TeamID INT FOREIGN KEY REFERENCES Teams(TeamID),
   Start_Work DATE NOT NULL,
   End_Work DATE NOT NULL,
   PRIMARY KEY(PlayerID, TeamID)
)
GO


IF OBJECT_ID(N'dbo.OutOfGame', N'U') IS NULL
CREATE TABLE OutOfGame (
   PlayerID INT FOREIGN KEY REFERENCES Players(PlayerID),
   Pause_Start DATE NOT NULL,
   Pause_End DATE,
   Reason VARCHAR(10) NOT NULL CHECK(Reason IN ('Cards', 'Injury')),
   PRIMARY KEY(PlayerID, Pause_Start)
)
GO

IF OBJECT_ID(N'dbo.Sponsors', N'U') IS NULL
CREATE TABLE Sponsors (
   SponsorID INT PRIMARY KEY, 
   SponsorName VARCHAR(50) NOT NULL,
   [Description] VARCHAR(100) NOT NULL
)
GO

IF OBJECT_ID(N'dbo.SponsorsTeams', N'U') IS NULL
CREATE TABLE SponsorsTeams (
   SponsorID INT FOREIGN KEY REFERENCES Sponsors(SponsorID), 
   TeamID INT FOREIGN KEY REFERENCES Teams(TeamID),
   Contract_Start DATE NOT NULL,
   Contract_End DATE,
   PRIMARY KEY(SponsorID, TeamID)
)
GO

IF OBJECT_ID(N'dbo.SponsorsPlayers', N'U') IS NULL
CREATE TABLE SponsorsPlayers (
   SponsorID INT FOREIGN KEY REFERENCES Sponsors(SponsorID), 
   PlayerID INT FOREIGN KEY REFERENCES Players(PlayerID),
   Contract_Start DATE NOT NULL,
   Contract_End DATE,
   PRIMARY KEY(SponsorID, PlayerID)
)
GO


IF OBJECT_ID(N'dbo.SeasonWinners', N'U') IS NULL
CREATE TABLE SeasonWinners (
   Season VARCHAR(15) PRIMARY KEY,
   WinnerID INT FOREIGN KEY REFERENCES Teams(TeamID),
   LastTeamID INT FOREIGN KEY REFERENCES Teams(TeamID),
   TopScorer VARCHAR(50)
)
GO
