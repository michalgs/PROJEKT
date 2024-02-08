USE ProjectDB
GO
CREATE VIEW CurrentCoaches
AS
	SELECT T.Team_Name Zespol, (C.Coach_Name + ' ' + C.Coach_Surname) Trener 
	FROM CoachTeam CT JOIN Teams T ON CT.TeamID = T.TeamID JOIN Coaches C ON CT.CoachID = C.CoachID
	WHERE End_Work IS NULL
GO

CREATE FUNCTION GetPlayersName (@ID INT)
RETURNS VARCHAR(50)
AS
BEGIN
	RETURN (SELECT (Player_Name + ' ' + Player_Surname) FROM Players WHERE PlayerID = @ID)
END
GO



CREATE VIEW TopScorers
AS
	SELECT TOP 50 [dbo].[GetPlayersName](MP.PlayerID) Zawodnik, SUM(MP.Goals_Scored) Bramki
	FROM MatchesPlayers MP JOIN Players P ON MP.PlayerID = P.PlayerID JOIN Teams T ON P.TeamID = T.TeamID
	WHERE MP.Goals_Scored > 0
	GROUP BY MP.PlayerID
	ORDER BY SUM(MP.Goals_Scored) DESC
GO

CREATE PROCEDURE TeamInfo @ID INT
AS
	SELECT T.Team_Name [Nazwa Zespolu], S.Stadium_Name Stadion, CC.Trener 
	FROM Teams T JOIN Stadiums S ON T.StadiumID = S.StadiumID JOIN CurrentCoaches CC ON T.Team_Name = CC.Zespol
	WHERE TeamID = @ID

	SELECT [dbo].[GetPlayersName](PlayerID) Zawodnicy FROM Players
	WHERE TeamID = @ID
GO

CREATE PROCEDURE TransferPlayer @TransferedPlayerID INT, @NewTeamID INT
AS
	UPDATE Players
	SET TeamID = @NewTeamID
	WHERE PlayerID = @TransferedPlayerID
GO



CREATE FUNCTION TeamNameFromID (@ID INT)
RETURNS VARCHAR(50)
AS
BEGIN
	RETURN (SELECT Team_Name FROM Teams WHERE TeamID = @ID)
END
GO

CREATE PROCEDURE Matchweek @Week INT
AS
	SELECT [dbo].[TeamNameFromID](M.FirstTeam) Gospodarz, [dbo].[TeamNameFromID](M.SecondTeam) Gosc, FirstTeamScore [' '], SecondTeamScore [' ']
    FROM Matches M JOIN LeagueMatches LM ON M.MatchID = LM.MatchID JOIN Teams T ON T.TeamID = M.FirstTeam
	WHERE LM.Matchweek = @Week
GO

CREATE FUNCTION CheckIfPlayerSuspended(@PID INT, @MatchDate DATE)
RETURNS BIT
AS
BEGIN
	DECLARE @StartDate DATE
	DECLARE @EndDate DATE
	-- Pobieramy daty zawieszen gracza i tworzymy kursor ktorym po nich przejdziemy
	DECLARE CursorSuspensions CURSOR
	FOR (SELECT Pause_Start, Pause_End FROM OutOfGame WHERE PlayerID = @PID)

	OPEN CursorSuspensions
	FETCH NEXT FROM CursorSuspensions INTO
		@StartDate,
		@EndDate;

	WHILE @@FETCH_STATUS = 0
		BEGIN
			-- Gdy data meczu w trakcie zawieszenia zwracamy TRUE
			IF @MatchDate BETWEEN @StartDate AND @EndDate
				RETURN 'TRUE'
			FETCH NEXT FROM CursorSuspensions INTO
				@StartDate,
				@EndDate;
		END
	RETURN 'FALSE'
END
GO

CREATE FUNCTION PlayerPlayedTheGame (@PID INT, @MID INT)
RETURNS BIT
AS
BEGIN
	-- Pobieramy indeksy zespolu zawodnika oraz uczestnikow danego meczu
	DECLARE @PlayersTeam INT = (SELECT TeamID FROM Players WHERE PlayerID = @PID)
	DECLARE @FirstTeam INT = (SELECT FirstTeam FROM Matches WHERE MatchID = @MID)
	DECLARE @SecondTeam INT = (SELECT SecondTeam FROM Matches WHERE MatchID = @MID)
	-- Sprawdzamy czy zawodnik wystepuje w ktoryms z zespolow z danego meczu
	DECLARE @PlayersTeamPlayed BIT = 
		(SELECT CASE WHEN (@PlayersTeam = @FirstTeam OR @PlayersTeam = @SecondTeam) 
					THEN 'TRUE' ELSE 'FALSE' END)

	-- Pobieramy date meczu
	DECLARE @MatchDate DATE = (SELECT Match_Date FROM Matches WHERE MatchID = @MID)
	-- Sprawdzamy czy zawodnik byl w tym dniu zawieszony
	DECLARE @PlayerSuspended BIT = [dbo].[CheckIfPlayerSuspended](@PID, @MatchDate)

	IF @PlayersTeamPlayed = 'TRUE' AND @PlayerSuspended = 'False'
			RETURN 'TRUE'
	RETURN 'FALSE'
END
GO

CREATE PROCEDURE AddPlayerContribution @MatchID INT, @PlayerID INT, @Goals INT, @YellowCards INT, @RedCards INT
AS
BEGIN
	IF [dbo].[PlayerPlayedTheGame](@PlayerID, @MatchID) = 'TRUE' AND (SELECT Is_Confirmed FROM Matches WHERE MatchID = @MatchID) = 0
		INSERT INTO MatchesPlayers
		VALUES (@MatchID, @PlayerID, @Goals, @YellowCards, @RedCards)
	ELSE
		PRINT 'Zawodnik nie uczestniczyl w meczu lub mecz potwierdzony'
END
GO

CREATE PROCEDURE ConfirmMatch (@MID INT)
AS
BEGIN
	-- Sprawdzamy czy mecz istnieje w bazie
	IF (SELECT MatchID FROM Matches WHERE MatchID = @MID) IS NULL
		RETURN

	-- W przypadku bezbramkowego remisu w tablicy dalej widnieja NULLE wiec zmienamy je na zera
	UPDATE Matches
	SET FirstTeamScore = CASE WHEN (SELECT FirstTeamScore FROM Matches WHERE MatchID = @MID) IS NULL THEN 0 ELSE FirstTeamScore END,
		SecondTeamScore = CASE WHEN (SELECT SecondTeamScore FROM Matches WHERE MatchID = @MID) IS NULL THEN 0 ELSE SecondTeamScore END
	WHERE MatchID = @MID

	-- Sprawdzamy czy potwierdzamy mecz ligowy
	IF (SELECT LM.MatchID FROM LeagueMatches LM JOIN Matches M ON LM.MatchID = M.MatchID WHERE LM.MatchID = @MID) IS NOT NULL
	BEGIN
		-- Jesli tak, to dodajemy punkty i bramki do tabeli ligowej
		DECLARE @HomeTeam INT = (SELECT FirstTeam FROM Matches WHERE MatchID = @MID),
				@AwayTeam INT = (SELECT SecondTeam FROM Matches WHERE MatchID = @MID),
				@HomeGoals INT = (SELECT FirstTeamScore FROM Matches WHERE MatchID = @MID),
				@AwayGoals INT = (SELECT SecondTeamScore FROM Matches WHERE MatchID = @MID)
				
		-- Update gospodarzy
		UPDATE LeagueTable
		SET Points = CASE WHEN (@HomeGoals > @AwayGoals) THEN
						Points + 3 
					 ELSE (CASE WHEN (@HomeGoals = @AwayGoals) THEN
					 		  Points + 1 
						   ELSE 
							  Points 
						   END)
					 END,
			GoalsScored = GoalsScored + @HomeGoals,
			GoalsConceded = GoalsConceded + @AwayGoals,
			Matches = Matches + 1
		WHERE TeamID = @HomeTeam
		
		-- Update gosci
		UPDATE LeagueTable
		SET Points = CASE WHEN (@AwayGoals > @HomeGoals) THEN
						Points + 3 
					 ELSE (CASE WHEN (@AwayGoals = @HomeGoals) THEN
					          Points + 1 
						   ELSE 
						   	  Points
						   END)
					 END,
			GoalsScored = GoalsScored + @AwayGoals,
			GoalsConceded = GoalsConceded + @HomeGoals,
			Matches = Matches + 1
		WHERE TeamID = @AwayTeam
	END
	
	-- Na koniec zmieniamy status Is_Confirmed na 1 niezaleznie od tego, czy mecz ligowy czy pucharowy
	UPDATE Matches
	SET Is_Confirmed = 1
	WHERE MatchID = @MID
END
GO

CREATE VIEW DisplayLeagueTable
AS
	SELECT TOP 16 [dbo].[TeamNameFromID](TeamID) Zespol, Matches [Mecze], Points [Punkty], GoalsScored [Bramki zdobyte], GoalsConceded [Bramki stracone]
	FROM LeagueTable
	ORDER BY [Punkty] DESC, [Bramki zdobyte] DESC, [Zespol] ASC
GO

CREATE VIEW DisplayPolishCup
AS
	SELECT PM.PlayOff_Round Runda, [dbo].[TeamNameFromID](M.FirstTeam) [Pierwszy zespol], [dbo].[TeamNameFromID](M.SecondTeam) [Drugi zespol], M.FirstTeamScore [Wynik], M.FirstTeamScore [koncowy],
	CASE WHEN (M.FirstTeamScore > M.SecondTeamScore) 
	THEN
		[dbo].[TeamNameFromID](M.FirstTeam)
	ELSE CASE WHEN (M.FirstTeamScore > M.SecondTeamScore) 
	THEN
		[dbo].[TeamNameFromID](M.SecondTeam)
 	END
	END Zwyciezca
	FROM PolishCupMatches PM JOIN Matches M ON PM.MatchID = M.MatchID

GO 

CREATE VIEW SeasonsHistory
AS
	SELECT Season [Sezon], [dbo].[TeamNameFromID](WinnerID) [Mistrz], [dbo].[TeamNameFromID](LastTeamID) [Spadkowicz], TopScorer [Krol strzelcow] 
	FROM SeasonWinners
GO

CREATE FUNCTION GetCupRound (@Round VARCHAR(50))
RETURNS TABLE
AS
	RETURN (SELECT * FROM PolishCupMatches WHERE [PlayOff_Round] = @Round)
GO