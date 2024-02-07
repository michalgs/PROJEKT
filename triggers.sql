--Pierwszy
CREATE TRIGGER Goals_Update
ON dbo.MatchesPlayers
AFTER INSERT
AS
BEGIN
	DECLARE @M_ID INT, @P_ID INT, @G INT
	DECLARE Iterator CURSOR FOR
	SELECT MatchID, PlayerID, Goals_Scored FROM INSERTED

	OPEN Iterator
	FETCH NEXT FROM Iterator INTO @M_ID, @P_ID, @G
	WHILE @@FETCH_STATUS = 0
		BEGIN
			DECLARE @Team_ID INT = (SELECT TeamID 
						FROM Players
						WHERE (PlayerID = @P_ID))
			DECLARE @First_Team INT = (SELECT FirstTeam FROM Matches WHERE (MatchID = @M_ID))

			IF @First_Team = @Team_ID
			BEGIN
				UPDATE Matches
				SET FirstTeamScore = ISNULL(FirstTeamScore, 0) + @G,
					SecondTeamScore = ISNULL(SecondTeamScore, 0)
				WHERE MatchID = @M_ID
				PRINT 'Dodano bramki pierwszej druzynie';

			END
			ELSE
			BEGIN 
				UPDATE Matches
				SET SecondTeamScore = ISNULL(SecondTeamScore, 0) + @G,
					FirstTeamScore = ISNULL(FirstTeamScore, 0)
				WHERE MatchID = @M_ID
				PRINT 'Dodano bramki drugiej druzynie';

			END
			FETCH NEXT FROM Iterator INTO @M_ID, @P_ID, @G
		END
		
	CLOSE Iterator
    PRINT 'Bramki zaktualizowane';
END;

GO
--Drugi
CREATE TRIGGER Referees_Update
ON dbo.Matches
AFTER INSERT
AS
BEGIN
	DECLARE @Ref_ID INT
	DECLARE Iterator CURSOR FOR
	SELECT RefereeID FROM INSERTED
	OPEN Iterator
	FETCH NEXT FROM Iterator INTO @Ref_ID
	WHILE @@FETCH_STATUS = 0	
		BEGIN
			UPDATE Referees
			SET Matches_Refereed = Matches_Refereed + 1
			WHERE RefereeID = @Ref_ID
			FETCH NEXT FROM Iterator INTO @Ref_ID
		END
	CLOSE Iterator
	DEALLOCATE Iterator
END 

GO
--Trzeci
CREATE TRIGGER End_Of_Season
ON dbo.Matches
AFTER UPDATE
AS
BEGIN
	IF (UPDATE(Is_confirmed) AND EXISTS (SELECT 1 FROM INSERTED WHERE MatchID = 2240))
    BEGIN
        PRINT 'Sezon zakonczony, wpisuje mistrza do tabeli';

		DECLARE @Year INT;
		SET @Year = YEAR(GETDATE()) - 8
		DECLARE @Season NVARCHAR(30) = FORMATMESSAGE('%d/%d', @Year-1, @Year);
		DECLARE @Winner INT = (SELECT TOP 1 TeamID FROM LeagueTable)
		DECLARE @LastTeam INT = ((SELECT TOP 16 TeamID FROM LeagueTable) EXCEPT (SELECT TOP 15 TeamID FROM LeagueTable))
		DECLARE @Top NVARCHAR(50) = (SELECT TOP 1 Zawodnik FROM TopScorers)
		
		INSERT INTO SeasonWinners VALUES
		(@Season, @Winner, @LastTeam, @Top)
		
		PRINT 'Wpisano wartosci dla sezonu'  + @Season + ':'
		PRINT 'Zwyciezca: ' + [dbo].[TeamNameFromID](@Winner)
		PRINT 'Spadkowicz: ' + [dbo].[TeamNameFromID](@LastTeam)
		PRINT 'Krol strzelcow: ' + @Top
	END
END 

GO
--Czwarty
CREATE TRIGGER Is_Red
ON dbo.MatchesPlayers
AFTER Insert
AS
BEGIN
	DECLARE @Player_ID INT
	DECLARE @Red INT
	DECLARE @Yellow INT
	DECLARE Iterator CURSOR FOR
	SELECT PlayerID, Yellow_Cards, Red_Cards FROM INSERTED
	OPEN Iterator
	FETCH NEXT FROM Iterator INTO @Player_ID, @Yellow, @Red
	WHILE @@FETCH_STATUS = 0	
		BEGIN
			IF @Red = 1 OR @Yellow = 2
			BEGIN
				DECLARE @Date DATE = CONVERT(DATE, DATEADD(YEAR, -5, GETDATE()))
				INSERT INTO OutOfGame VALUES
				(@Player_ID, @Date, CONVERT(DATE, DATEADD(DAY, +10, @Date)), 'Cards')
			END
		FETCH NEXT FROM Iterator INTO @Player_ID, @Yellow, @Red
		END
	CLOSE Iterator
	DEALLOCATE Iterator
END 

--Piaty
GO
CREATE TRIGGER Add_Yellow_Red
ON dbo.MatchesPlayers
AFTER Insert
AS
BEGIN
	DECLARE @Match_ID INT
	DECLARE @Yellow INT
	DECLARE @Red INT
	DECLARE Iterator CURSOR FOR
	SELECT MatchID, Yellow_Cards, Red_Cards FROM INSERTED
	OPEN Iterator
	FETCH NEXT FROM Iterator INTO @Match_ID, @Yellow, @Red
	WHILE @@FETCH_STATUS = 0	
		BEGIN
			DECLARE @Ref_ID INT = (SELECT RefereeID FROM Matches WHERE MatchID = @Match_ID)
			IF @Yellow = 1 OR @Red = 0
			BEGIN
				UPDATE Referees 
				SET Yellow_Cards_Given = Yellow_Cards_Given + @Yellow,
					Red_Cards_Given = Red_Cards_Given + @Red
				WHERE RefereeID = @Ref_ID
			END

			IF @Yellow = 2
			BEGIN
				UPDATE Referees 
				SET Yellow_Cards_Given = Yellow_Cards_Given + @Yellow
				WHERE RefereeID = @Ref_ID
			END

		FETCH NEXT FROM Iterator INTO @Match_ID, @Yellow, @Red
		END
	CLOSE Iterator
	DEALLOCATE Iterator
END 
