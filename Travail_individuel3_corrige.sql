
-- Notes:
-- 1) On crée LibreSpaceDW depuis master (sinon DROP peut échouer).
-- 2) On utilise la BD source: LibreSpaceTransacDB (nom attendu dans la solution).
-- 3) On ajoute DateModification + triggers dans les tables sources pour l'ETL incrémental.
-- ============================================================

-- CRER LA COQUILLE DE L'ENTREPT DE DONNES
USE Master
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name='LibreSpaceDW')
--ALTER DATABASE [LibreSpaceDW] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP DATABASE LibreSpaceDW
GO

CREATE DATABASE LibreSpaceDW
GO

USE LibreSpaceDW
GO

-- Cration de la table ETLConfig pour grer les valeurs  mettre  jour ou insrer
IF EXISTS (SELECT * FROM sys.tables WHERE name= 'LibreSpaceDW_ETLConfig')
DROP TABLE LibreSpaceDW_ETLConfig
GO

CREATE TABLE LibreSpaceDW_ETLConfig
(
	nomTable NVARCHAR(25), 
	dateDerniereModification DATETIME DEFAULT 0
)
GO

/************************/
/**** DIMENSION DATE ****/
/************************/

USE LibreSpaceDW
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'DIM_DATE')
DROP TABLE DIM_DATE

CREATE TABLE DIM_DATE
(
	refDate				INT IDENTITY (1,1) PRIMARY KEY,
	valeurDate			date NOT NULL,
	Annee				smallint NOT NULL,
	Mois				smallint NOT NULL,
	JourSemaine			varchar(12) NOT NULL,
);

-- Chargement incrmental de dim_date
SET DATEFIRST 7;

WITH CalendrierCTE (dateCourante)
AS
(
    SELECT COALESCE(MAXDate.MaxDate, '2020-01-01') AS DateCourante
    FROM (SELECT MAX(ValeurDate) AS MaxDate FROM dim_Date) AS MaxDate

    UNION ALL 

    SELECT DATEADD(DAY, 1, C.DateCourante)
    FROM CalendrierCTE C
    WHERE C.dateCourante < GETDATE()+7
)


INSERT INTO dim_Date (ValeurDate, Annee, Mois, JourSemaine)
SELECT 		
    C.dateCourante,
    YEAR(C.dateCourante),
    MONTH(C.dateCourante),
    DATENAME(WEEKDAY, C.dateCourante)
FROM CalendrierCTE C 
WHERE NOT EXISTS (
    SELECT 1 
    FROM DIM_DATE 
    WHERE ValeurDate = dateCourante
)
OPTION (MAXRECURSION 12000);

/*******************************/
/**** DIMENSION FOURNISSEUR ****/
/*******************************/

USE LibreSpaceTransacDB
GO
-- Ajout de l'attribut DateModification
IF EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Fournisseur' AND COLUMN_NAME = 'DateModification'
)
BEGIN
    UPDATE Fournisseur
    SET DateModification = GETDATE();
END
ELSE
BEGIN
    ALTER TABLE Fournisseur
    ADD DateModification DATETIME DEFAULT GETDATE();
END;

Go

-- Ajout d'un trigger

IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trFournisseur')
DROP TRIGGER trFournisseur
GO

CREATE TRIGGER trFournisseur ON Fournisseur
AFTER UPDATE
AS
BEGIN
        UPDATE Fournisseur
        SET DateModification = GETDATE()
        FROM Fournisseur AS F
        JOIN INSERTED I ON F.IdFournisseur = I.IdFournisseur;
END
GO

-- Cration de la table DIM_FOURNISSEUR
USE LibreSpaceDW
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'DIM_FOURNISSEUR')
DROP TABLE DIM_FOURNISSEUR
GO
CREATE TABLE DIM_FOURNISSEUR (
    RefFournisseur INT IDENTITY (1,1) CONSTRAINT PK_RefFournisseur PRIMARY KEY
    , IdFournisseur INT NOT NULL
    , NomFournisseur VARCHAR(255) NOT NULL
    , Telephone VARCHAR(20) NOT NULL
    , DateMAJDimFournisseur DATE NOT NULL DEFAULT GETDATE()
);

DELETE FROM LibreSpaceDW_ETLConfig WHERE nomTable = 'DIM_FOURNISSEUR'
INSERT INTO LibreSpaceDW_ETLConfig (nomTable) VALUES ('DIM_FOURNISSEUR')

Go

-- Crer la vue (staging area) o les transformations seront effectues
IF EXISTS (SELECT * FROM sys.views WHERE name='vue_Fournisseur')
DROP VIEW vue_Fournisseur
GO

CREATE VIEW vue_Fournisseur
AS

SELECT F.IdFournisseur, F.NomFournisseur, F.Telephone
FROM LibreSpaceTransacDB.dbo.Fournisseur F
	WHERE DateModification > (
    SELECT dateDerniereModification
    FROM LibreSpaceDW.dbo.LibreSpaceDW_ETLConfig
    WHERE nomTable = 'DIM_FOURNISSEUR')
	;
Go

/* Peuplement incrmental des enregistrements */

MERGE DIM_FOURNISSEUR AS TARGET
USING vue_Fournisseur AS SOURCE ON TARGET.IdFournisseur = SOURCE.IdFournisseur 

WHEN MATCHED
	THEN UPDATE SET TARGET.Telephone = SOURCE.Telephone, TARGET.NomFournisseur = SOURCE.NomFournisseur

WHEN NOT MATCHED BY TARGET
	THEN INSERT (IdFournisseur, NomFournisseur, Telephone, DateMAJDimFournisseur) VALUES (SOURCE.IdFournisseur, SOURCE.NomFournisseur, SOURCE.Telephone, getdate())
                                                                                                      
OUTPUT $action AS Action
, Source.*;

UPDATE LibreSpaceDW_ETLConfig
SET dateDerniereModification = getdate()
WHERE nomTable = 'DIM_FOURNISSEUR'

GO


/*******************************/
/**** DIMENSION LIVRE ****/
/*******************************/

USE LibreSpaceTransacDB
GO
-- Ajout de l'attribut DateModification
IF EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Livre' AND COLUMN_NAME = 'DateModification'
)
BEGIN
    UPDATE Livre
    SET DateModification = GETDATE();
END
ELSE
BEGIN
    ALTER TABLE Livre
    ADD DateModification DATETIME DEFAULT GETDATE();
END;

Go

IF EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'AuteurLivre' AND COLUMN_NAME = 'DateModification'
)
BEGIN
    UPDATE AuteurLivre
    SET DateModification = GETDATE();
END
ELSE
BEGIN
    ALTER TABLE AuteurLivre
    ADD DateModification DATETIME DEFAULT GETDATE();
END;

Go

IF EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'QuantiteStock' AND COLUMN_NAME = 'DateModification'
)
BEGIN
    UPDATE QuantiteStock
    SET DateModification = GETDATE();
END
ELSE
BEGIN
    ALTER TABLE QuantiteStock
    ADD DateModification DATETIME DEFAULT GETDATE();
END;

Go

IF EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Editeur' AND COLUMN_NAME = 'DateModification'
)
BEGIN
    UPDATE Editeur
    SET DateModification = GETDATE();
END
ELSE
BEGIN
    ALTER TABLE Editeur
    ADD DateModification DATETIME DEFAULT GETDATE();
END;

Go

-- Ajout des triggers
-- Trigger sur Livre
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trLivre')
DROP TRIGGER trLivre
GO

CREATE TRIGGER trLivre ON Livre
AFTER UPDATE
AS
BEGIN
        UPDATE Livre
        SET DateModification = GETDATE()
        FROM Livre AS L
        JOIN INSERTED I ON L.idLivre = I.idLivre;
END
GO
-- Trigger sur Livre
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trAuteurLivre')
DROP TRIGGER trAuteurLivre
GO

CREATE TRIGGER trAuteurLivre ON AuteurLivre
AFTER UPDATE, INSERT
AS
BEGIN
        UPDATE AuteurLivre
        SET DateModification = GETDATE()
        FROM AuteurLivre AS AL
        JOIN INSERTED I ON AL.idLivre = I.idLivre;
END
GO

-- Trigger sur QuantiteStock
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trQuantiteStock')
DROP TRIGGER trQuantiteStock
GO

CREATE TRIGGER trQuantiteStock ON QuantiteStock
AFTER UPDATE, INSERT
AS
BEGIN
        UPDATE QuantiteStock
        SET DateModification = GETDATE()
        FROM QuantiteStock AS QS
        JOIN INSERTED I ON QS.IdStock = I.IdStock;
END
GO

-- Trigger sur Editeur
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trEditeur')
DROP TRIGGER trEditeur
GO

CREATE TRIGGER trEditeur ON Editeur
AFTER UPDATE
AS
BEGIN
        UPDATE Editeur
        SET DateModification = GETDATE()
        FROM Editeur AS E
        JOIN INSERTED I ON E.IdEditeur = I.IdEditeur;
END
GO

-- Cration de la table DIM_LIVRE
USE LibreSpaceDW
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'DIM_LIVRE')
DROP TABLE DIM_LIVRE
GO
CREATE TABLE DIM_LIVRE (
    RefLivre INT					IDENTITY (1,1) CONSTRAINT PK_refLivre PRIMARY KEY
    , IdLivre INT					NOT NULL
    , Prix DECIMAL(10,2)			NOT NULL 
    , AnneePublication DATE			NOT NULL 
    , QuantiteStock INT				NOT NULL 
    , NomGenre VARCHAR(255)			NOT NULL 
    , IdEditeur INT					NOT NULL 
    , PaysEditeur VARCHAR(255)		NOT NULL 
    , NombreAuteurs INT				NOT NULL
	, DateMEA DATETIME NOT NULL DEFAULT getdate()
	, DateEXP DATETIME NOT NULL DEFAULT CONVERT(date,'9999-12-31')
	, Statut NVARCHAR(10)  NOT NULL DEFAULT 'Courant'
    , DateMAJDimLivre DATE			NOT NULL DEFAULT GETDATE()
);


DELETE FROM LibreSpaceDW_ETLConfig WHERE nomTable = 'DIM_LIVRE'
INSERT INTO LibreSpaceDW_ETLConfig (nomTable) VALUES ('DIM_LIVRE')

Go

-- Crer la vue (staging area) o les transformations seront effectues
USE LibreSpaceDW
GO

IF EXISTS (SELECT * FROM sys.views WHERE name='vue_Livre')
DROP VIEW vue_Livre
GO

CREATE VIEW vue_Livre
AS

SELECT 
    L.idLivre, 
    L.Prix, 
    L.ISBN, 
    L.ISSN, 
    L.Titre, 
    L.AnneePublication, 
    QS.QuantiteStock, 
    G.NomGenre, 
    E.IdEditeur, 
    E.Pays AS PaysEditeur,
    (SELECT COUNT(*) 
     FROM LibreSpaceTransacDB.dbo.AuteurLivre 
     WHERE IdLivre = L.idLivre) AS NombreAuteurs
FROM 
    LibreSpaceTransacDB.dbo.Livre L
    INNER JOIN LibreSpaceTransacDB.dbo.Genre G ON G.IdGenre = L.IdGenre
    INNER JOIN LibreSpaceTransacDB.dbo.QuantiteStock QS ON QS.idLivre = L.idLivre
    INNER JOIN LibreSpaceTransacDB.dbo.Editeur E ON E.IdEditeur = L.IdEditeur
	INNER JOIN LibreSpaceTransacDB.dbo.AuteurLivre AL ON AL.IdLivre = L.idLivre
WHERE 
    (
        SELECT 
            CASE 
                WHEN L.DateModification >= QS.DateModification AND L.DateModification >= E.DateModification AND L.DateModification >= AL.DateModification THEN L.DateModification
                WHEN AL.DateModification >= L.DateModification AND AL.DateModification >= QS.DateModification AND AL.DateModification >= E.DateModification THEN AL.DateModification
                WHEN QS.DateModification >= L.DateModification AND QS.DateModification >= AL.DateModification AND QS.DateModification >= E.DateModification THEN QS.DateModification
                ELSE E.DateModification
            END
        FROM
            LibreSpaceDW.dbo.LibreSpaceDW_ETLConfig
        WHERE 
            nomTable = 'DIM_LIVRE'
    ) > (
        SELECT dateDerniereModification
        FROM LibreSpaceDW.dbo.LibreSpaceDW_ETLConfig
        WHERE nomTable = 'DIM_LIVRE'
    );

Go


/* Peuplement incrmental des enregistrements */

INSERT INTO DIM_LIVRE (idLivre, Prix, AnneePublication, QuantiteStock, NomGenre, IdEditeur, PaysEditeur, NombreAuteurs)
SELECT idLivre, Prix, AnneePublication, QuantiteStock, NomGenre, IdEditeur, PaysEditeur, NombreAuteurs
FROM (
	MERGE DIM_LIVRE AS TARGET
	USING vue_Livre AS SOURCE ON TARGET.idLivre = SOURCE.idLivre 

	WHEN MATCHED
		AND TARGET.statut = 'Courant' 
		THEN UPDATE SET TARGET.statut = 'Expir', TARGET.dateEXP = getdate()

	WHEN NOT MATCHED BY TARGET
		THEN INSERT (idLivre, Prix, AnneePublication, QuantiteStock, NomGenre, IdEditeur, PaysEditeur, NombreAuteurs, DateMAJDimLivre) VALUES (SOURCE.idLivre, SOURCE.Prix, SOURCE.AnneePublication, SOURCE.QuantiteStock, SOURCE.NomGenre, SOURCE.IdEditeur, SOURCE.PaysEditeur, SOURCE.NombreAuteurs, getdate())
                                                                                                      
    OUTPUT $action AS Action
	, Source.*

) AS MergeOutput

WHERE MergeOutput.Action = 'UPDATE'

UPDATE LibreSpaceDW_ETLConfig
SET dateDerniereModification = getdate()
WHERE nomTable = 'DIM_LIVRE'

GO

USE LibreSpaceTransacDB
GO
-- Ajout de l'attribut DateModification
IF EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'CommandeLivre' AND COLUMN_NAME = 'DateModification'
)
BEGIN
    UPDATE CommandeLivre
    SET DateModification = GETDATE();
END
ELSE
BEGIN
    ALTER TABLE CommandeLivre
    ADD DateModification DATETIME DEFAULT GETDATE();
END;

Go

IF EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'CommandeFournisseur' AND COLUMN_NAME = 'DateModification'
)
BEGIN
    UPDATE CommandeFournisseur
    SET DateModification = GETDATE();
END
ELSE
BEGIN
    ALTER TABLE CommandeFournisseur
    ADD DateModification DATETIME DEFAULT GETDATE();
END;

Go

-- Ajout des triggers
-- Trigger sur CommandeLivre
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trCommandeLivre')
DROP TRIGGER trCommandeLivre
GO

CREATE TRIGGER trCommandeLivre ON CommandeLivre
AFTER UPDATE
AS
BEGIN
        UPDATE CommandeLivre
        SET DateModification = GETDATE()
        FROM CommandeLivre AS CL
        JOIN INSERTED I ON CL.IdCommandeLivre = I.IdCommandeLivre;
END
GO

-- Trigger sur CommandeFournisseur
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trCommandeFournisseur')
DROP TRIGGER trCommandeFournisseur
GO

CREATE TRIGGER trCommandeFournisseur ON CommandeFournisseur
AFTER UPDATE
AS
BEGIN
        UPDATE CommandeFournisseur
        SET DateModification = GETDATE()
        FROM CommandeFournisseur AS CF
        JOIN INSERTED I ON CF.idCdeFournisseur = I.idCdeFournisseur;
END
GO

-- Cration de la table Fait_CommandeLivre
USE LibreSpaceDW
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Fait_CommandeLivre')
DROP TABLE Fait_CommandeLivre
GO

CREATE TABLE Fait_CommandeLivre (
    RefDateCommande				INT				NOT NULL
    , RefDateReception			INT				NOT NULL
    , RefFournisseur			INT				NOT NULL
    , RefLivre					INT				NOT NULL
    , IdCommandeLivre			INT				NOT NULL
	, IdCdeFournisseur			INT				NOT NULL
    , QuantiteCommandees		INT				NOT NULL
    , TotalCommande				DECIMAL(10,2)	NOT NULL
    , StatutCommande			VARCHAR(255)	NOT NULL
    , CoutUnitaire				DECIMAL(10,2)	NOT NULL
    , MargeBrute				DECIMAL(10,2)	NOT NULL
    , DateMAJFait				DATE			NOT NULL DEFAULT GETDATE()
	)

Delete from LibreSpaceDW_ETLConfig where nomTable = 'Fait_CommandeLivre'
INSERT INTO LibreSpaceDW_ETLConfig (nomTable) VALUES ('Fait_CommandeLivre')

GO

-- Cration de la vue 

USE LibreSpaceDW
GO

IF EXISTS (SELECT * FROM sys.views WHERE name='vue_CommandeLivre')
DROP VIEW vue_CommandeLivre
GO

CREATE VIEW vue_CommandeLivre
AS
WITH DerniereModificationCTE AS (
    SELECT dateDerniereModification
    FROM LibreSpaceDW.dbo.LibreSpaceDW_ETLConfig
    WHERE nomTable = 'Fait_CommandeLivre'
)

SELECT 
    CL.idCommandeLivre, 
    CF.idCdeFournisseur,
	CL.idLivre,
	CL.QuantiteCommandee, 
    CL.CoutUnitaire, 
    CF.StatutCommande, 
	CF.idFournisseur,
    CF.TotalCommande,
	CF.DateCommande,
	CF.DateReception,
    DATEDIFF(day, CF.DateCommande, CF.DateReception) as DelaiReception,
    L.Prix - CL.CoutUnitaire AS MargeBrute
FROM LibreSpaceTransacDB.dbo.CommandeLivre CL
INNER JOIN LibreSpaceTransacDB.dbo.CommandeFournisseur CF ON CF.idCdeFournisseur = CL.idCdeFournisseur
INNER JOIN LibreSpaceTransacDB.dbo.Livre L ON L.idLivre = CL.idLivre
WHERE 
    CF.StatutCommande = 'Paye'
    AND CF.DateReception > (
        SELECT dateDerniereModification
        FROM LibreSpaceDW.dbo.LibreSpaceDW_ETLConfig
        WHERE nomTable = 'Fait_CommandeLivre')
GO

-- Peupler le Fait

INSERT INTO Fait_CommandeLivre (RefDateCommande, RefDateReception, RefLivre, RefFournisseur, IdCommandeLivre, IdCdeFournisseur, QuantiteCommandees, TotalCommande, StatutCommande, CoutUnitaire, MargeBrute, DateMAJFait)
SELECT DD1.refDate, DD2.refDate, DL.IdLivre, VCL.idFournisseur, VCL.idCommandeLivre, VCL.idCdeFournisseur, VCL.QuantiteCommandee, VCL.TotalCommande, VCL.StatutCommande, VCL.CoutUnitaire, VCL.MargeBrute, GETDATE()
FROM vue_CommandeLivre VCL
	INNER JOIN DIM_DATE DD1 ON DD1.valeurDate = VCL.DateCommande
	INNER JOIN DIM_DATE DD2 ON DD2.valeurDate = VCL.DateReception
	INNER JOIN DIM_LIVRE DL ON DL.IdLivre = VCL.idLivre
	INNER JOIN DIM_FOURNISSEUR DF ON DF.IdFournisseur = VCL.idFournisseur

	UPDATE LibreSpaceDW_ETLConfig
	SET dateDerniereModification = getdate()
	WHERE nomTable = 'Fait_CommandeLivre'

GO

-- Quelques requtes de test (non demandes pour le TP)
USE LibreSpaceDW
GO

Select* 
from Fait_CommandeLivre FCL
	INNER JOIN DIM_DATE DD1 ON DD1.refDate = FCL.RefDateCommande
	INNER JOIN DIM_DATE DD2 ON DD2.refDate = FCL.RefDateReception
	INNER JOIN DIM_LIVRE DL ON DL.IdLivre = FCL.RefLivre
	INNER JOIN DIM_FOURNISSEUR DF ON DF.IdFournisseur = FCL.RefFournisseur

SELECT *
FROM DIM_LIVRE
WHERE NombreAuteurs > 1;

SELECT TOP 3 DF.NomFournisseur, SUM(FC.TotalCommande) AS MontantTotalCommandes, COUNT(*) AS NombreCommandes, SUM(fc.margebrute) AS 'Marge brute'
FROM DIM_FOURNISSEUR DF
INNER JOIN Fait_CommandeLivre FC ON DF.RefFournisseur = FC.RefFournisseur
INNER JOIN DIM_LIVRE DL ON FC.RefLivre = DL.RefLivre
WHERE DL.NomGenre = 'Drame'
GROUP BY DF.NomFournisseur
ORDER BY MontantTotalCommandes DESC;


WITH FournisseurClassement AS (
SELECT 
    DF.NomFournisseur,
    DL.NomGenre,
    SUM(FC.TotalCommande) AS MontantTotalCommande,
    ROW_NUMBER() OVER (PARTITION BY DL.NomGenre ORDER BY SUM(FC.TotalCommande) DESC) AS RangFournisseur
FROM Fait_CommandeLivre FC
JOIN DIM_FOURNISSEUR DF ON FC.RefFournisseur = DF.RefFournisseur
JOIN DIM_LIVRE DL ON FC.RefLivre = DL.RefLivre
GROUP BY DF.NomFournisseur, DL.NomGenre
)
SELECT NomGenre, NomFournisseur, MontantTotalCommande
FROM FournisseurClassement
WHERE RangFournisseur <= 1;

/* ============================================================
   CONTRÔLES RAPIDES (optionnel)
   ============================================================ */

USE LibreSpaceDW;
GO

-- Dimensions (devraient être peuplées)
SELECT TOP (100) * FROM dbo.DIM_DATE ORDER BY DateValue DESC;
SELECT TOP (100) * FROM dbo.DIM_FOURNISSEUR ORDER BY idFournisseur;
SELECT TOP (100) * FROM dbo.DIM_LIVRE ORDER BY idLivre, dateDebut DESC;

-- Vues (si présentes dans ta version)
IF OBJECT_ID('dbo.vue_Fournisseur','V') IS NOT NULL
    SELECT TOP (100) * FROM dbo.vue_Fournisseur;
IF OBJECT_ID('dbo.vue_Livre','V') IS NOT NULL
    SELECT TOP (100) * FROM dbo.vue_Livre;
GO
