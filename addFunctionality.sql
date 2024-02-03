--DROP DATABASE ProjectDB
USE ProjectDB
GO
CREATE VIEW CurrentCoaches
AS
	SELECT T.Team_Name Zespol, (C.Coach_Name + ' ' + C.Coach_Surname) Trener 
	FROM CoachTeam CT JOIN Teams T ON CT.TeamID = T.TeamID JOIN Coaches C ON CT.CoachID = C.CoachID
	WHERE End_Work IS NULL
GO

CREATE PROCEDURE TeamInfo @ID INT
AS
	SELECT T.Team_Name [Nazwa Zespolu], S.Stadium_Name Stadion, CC.Trener 
	FROM Teams T JOIN Stadiums S ON T.StadiumID = S.StadiumID JOIN CurrentCoaches CC ON T.Team_Name = CC.Zespol
	WHERE TeamID = @ID

	SELECT (Player_Name + ' ' + Player_Surname) Zawodnicy FROM Players
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

