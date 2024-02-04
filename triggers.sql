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

--Drugi
CREATE TRIGGER RefereesUpdate
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