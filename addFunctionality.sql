--DROP DATABASE ProjectDB
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

CREATE VIEW LeagueTable
AS
	SELECT T.Team_Name Zespol, 0 [Mecze], 0 Punkty, 0 [Bramki zdobyte], 0 [Bramki stracone]
	FROM Teams T
	ORDER BY [Punkty], [Bramki zdobyte], Zespol
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
	IF [dbo].[PlayerPlayedTheGame](@PlayerID, @MatchID) = 'TRUE'
		INSERT INTO MatchesPlayers
		VALUES (@MatchID, @PlayerID, @Goals, @YellowCards, @RedCards)
	ELSE
		PRINT 'Zawodnik nie uczestniczyl w meczu'
END
GO

