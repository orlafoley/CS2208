# Pub(PLN, PubName, PCounty)
# NeighbourCounty(County1, County2)
# Person(PPSN, PName, PCounty, Age, DailyPubLimit)
# Visit(PLN, PPSN, StartDateOfVisit, EndDateOfVisit)
# Covid_Diagnosis(PPSN, DiagnosisDate, IsolationEndDate)

DROP TABLE IF EXISTS Covid_Diagnosis;
DROP TABLE IF EXISTS Visit;
DROP TABLE IF EXISTS Person;
DROP TABLE IF EXISTS NeighbourCounty;
DROP TABLE IF EXISTS Pub;

/* Write SQL statements to create the tables
   (including primary keys and foreign keys).*/

CREATE TABLE Pub (
    PLN         char(5),
    PubName     varchar(20),
    PCounty     varchar(15),
    PRIMARY KEY(PLN)
);

CREATE TABLE NeighbourCounty (
    County1     varchar(15),
    County2     varchar(15),
    PRIMARY KEY(County1, County2)
);

CREATE TABLE Person (
    PPSN            int,
    PName           varchar(15),
    PCounty         varchar(15),
    Age             int,
    DailyPubLimit   int,
    PRIMARY KEY(PPSN)
);

CREATE TABLE Visit (
    PLN                 char(5),
    PPSN                int,
    StartDateOfVisit    DATETIME,
    EndDateOfVisit      DATETIME,
    PRIMARY KEY(PLN, PPSN, StartDateOfVisit, EndDateOfVisit),
    FOREIGN KEY(PLN) REFERENCES Pub(PLN) ON DELETE CASCADE,
    FOREIGN KEY(PPSN) REFERENCES Person(PPSN) ON DELETE CASCADE
);

CREATE TABLE Covid_Diagnosis (
    PPSN                int,
    DiagnosisDate       DATE,
    IsolationEndDate    DATE,
    PRIMARY KEY(PPSN),
    FOREIGN KEY(PPSN) REFERENCES Person(PPSN) ON DELETE CASCADE
);

/* Populate the DB with the following information.*/

INSERT INTO Pub VALUES
    ('L1234', 'Murphy\'s', 'Cork'),
    ('L2345', 'Joe\'s', 'Limerick'),
    ('L3456', 'BatBar', 'Kerry');

INSERT INTO NeighbourCounty VALUES
    ('Cork', 'Limerick'),
    ('Limerick', 'Cork'),
    ('Cork', 'Kerry'),
    ('Kerry', 'Cork');

INSERT INTO Person VALUES
    (1, 'Liza', 'Cork', 22, 5),
    (2, 'Alex', 'Limerick', 19, 7),
    (3, 'Tom', 'Kerry', 23, 10),
    (4, 'Peter', 'Cork', 39, 8);

INSERT INTO Visit VALUES
    ('L1234', 1, '2020/10/02 10:00', '2020/10/02 11:00');
INSERT INTO Visit VALUES
    ('L1234', 1, '2020/08/12 11:00', '2020/08/12 11:35');
INSERT INTO Visit VALUES
    ('L2345', 3, '2020/03/12 11:00', '2020/03/12 11:50');

INSERT INTO Covid_Diagnosis VALUES
    (2, '2020-02-11', '2020-02-21');

/* An infected person cannot visit any Pub
   during the isolation period, i.e., from
   the diagnosis date and before the end
   of isolation.*/

DROP TRIGGER IF EXISTS noPubVisits;

DELIMITER //
    CREATE TRIGGER noPubVisits
        BEFORE INSERT ON Visit
        FOR EACH ROW
        BEGIN
            IF ((NEW.StartDateOfVisit BETWEEN
                (SELECT DiagnosisDate FROM Covid_Diagnosis)
                AND (SELECT IsolationEndDate FROM Covid_Diagnosis))
                AND NEW.PPSN = (SELECT PPSN FROM Covid_Diagnosis))
                THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Sorry Homer, you can\'t go to Moe\'s.';
            END IF;
        END; //
DELIMITER ;

/*In order to reduce the spread of the virus
  in this hypothetical system a person can only
  visit Pubs in a restricted area, for the
  context of this project that would be in
  the same county of residence or a
  neighbour county.*/

DROP TRIGGER IF EXISTS onlyNearbyCounties;

DELIMITER //
        CREATE TRIGGER onlyNearbyCounties
        BEFORE INSERT ON Visit
        FOR EACH ROW
        BEGIN
            IF NOT (NEW.PLN IN
                (SELECT Pub.PLN
                FROM Pub
                WHERE Pub.PCounty =
                    (SELECT Person.PCounty
                    FROM Person
                    WHERE Person.PPSN = NEW.PPSN)
                        OR Pub.PCounty IN
                    (SELECT DISTINCT NC.County2
                    FROM NeighbourCounty AS NC
                    WHERE NC.County1 IN
                        (SELECT DISTINCT Person.PCounty
                        FROM Person
                        WHERE Person.PPSN = NEW.PPSN))))
                THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Sorry Homer, you can\'t leave Springfield.';
            END IF;
        END; //
DELIMITER ;

/* In order to further reduce the spread
  of the virus, in this hypothetical system,
  a person is only allowed to visit a certain
  number of Pubs in a 24 hour period,
  i.e., (DailyPubLimit) and of course
  the same person cannot visit more than
  1 Pub at the same time.*/

#DROP TRIGGER IF EXISTS noDuplicates;
#DELIMITER //
#    CREATE TRIGGER noDuplicates
#    BEFORE INSERT ON Visit
#    FOR EACH ROW
#        BEGIN
#            IF (NEW.StartDateOfVisit BETWEEN
#                (SELECT Visit.StartDateOfVisit
#                FROM Visit
#                WHERE Visit.PPSN = NEW.PPSN)
#                    AND
#                (SELECT Visit.EndDateOfVisit
#                FROM Visit
#                WHERE Visit.PPSN = NEW.PPSN)) THEN
#            SIGNAL SQLSTATE '45000'
#            SET MESSAGE_TEXT = 'The only duplicates we allow are Patty and Selma or Sherri and Terri.';
#            END IF;
#        END //
#DELIMITER ;


#DROP TRIGGER IF EXISTS pubLimits;
#DELIMITER //
#    CREATE TRIGGER pubLimits
#        BEFORE INSERT ON Visit
#        FOR EACH ROW
#        BEGIN
#            IF
#                ((SELECT COUNT(*)
#                FROM Visit
#                WHERE PPSN = (NEW.PPSN) AND StartDateOfVisit BETWEEN (SELECT DATE(NEW.StartDateOfVisit))
#                    AND (SELECT DATE_ADD((SELECT DATE(NEW.StartDateOfVisit)), INTERVAL 1 DAY)))
#                >
#                (SELECT DailyPubLimit
#                FROM Person
#                WHERE PPSN = NEW.PPSN))
#
#                THEN
#                SIGNAL SQLSTATE '45000'
#                SET MESSAGE_TEXT = 'You shall not pass!';
#            END IF;
#        END //
#DELIMITER ;


/* Create a view (named COVID_NUMBERS) to retrieve
   the number of COVID cases for each county in the
   database. This view will output two columns named
   county and cases.*/

CREATE OR REPLACE VIEW COVID_NUMBERS AS
    SELECT P.PCounty AS 'County', COUNT(*) AS 'Cases'
    FROM Covid_Diagnosis AS CD
    JOIN Person AS P
    ON P.PPSN = CD.PPSN
    GROUP BY P.PCounty;

SELECT * FROM COVID_NUMBERS;