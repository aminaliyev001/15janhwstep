--1. SP "Factorial". SP calculates the factorial of a given number. (5! = 1 * 2 * 3 * 4 * 5 = 120 ) 
--(the factorial of a negative number does not exist).
CREATE PROCEDURE faktorial
    @eded INT
AS
BEGIN
	DECLARE @Result INT = 1
    IF @eded <= 0
		BEGIN
		RETURN 0
		END
	ELSE 
		BEGIN
			WHILE @eded >= 1
				BEGIN
					SET @Result*=@eded
					SET @eded -= 1
				END
		END
	RETURN @Result
END

DECLARE @output1 INT
EXEC @output1 = faktorial 5
PRINT @output1

--2. SP "Lazy Students." SP displays students who never took books in the library 
--and through the output parameter returns the number of these students.

CREATE PROCEDURE task2
AS
BEGIN
	DECLARE @Count INT
	SELECT @Count = COUNT(*) FROM Students S LEFT JOIN S_Cards ON S_Cards.Id_Student = S.Id WHERE S_Cards.Id IS NULL
	RETURN @Count
END

DECLARE @Output2 INT
EXEC @Output2 = task2
PRINT @Output2

--3. SP "Books on the criteria." SP displays a list of books that matching criterion: the author's name, surname, subject, category. In addition, the list should be sorted by the column number specified in the 5th parameter, in the direction indicated in parameter 6. 
--Columns: 1) book identifier, 2) book title, 3) surname and name of the author, 4) topic, 5) category.

CREATE PROC task3
@authorname NVARCHAR(20),
@authorsurname NVARCHAR(20),
@subject NVARCHAR(20),
@category NVARCHAR(20),
@columnname NVARCHAR(20),
@direction NVARCHAR(4)
AS BEGIN
	SELECT B.Id AS [Book ID], B.Name AS [Book Name], A.FirstName + ' '+A.LastName AS [Author name surname], Themes.Name AS [Theme Name], Categories.Name AS [Category Name]
	FROM Books B 
	INNER JOIN Authors A ON A.Id = B.Id_Author
	INNER JOIN Themes ON Themes.Id = B.Id_Themes
	INNER JOIN Categories ON Categories.Id = B.Id_Category
	WHERE A.FirstName = @authorname AND A.LastName = @authorsurname AND Themes.Name = @subject AND Categories.Name = @category 
	    ORDER BY 
        CASE WHEN @columnname = 'Id' AND @direction = 'ASC' THEN B.Id END ASC,
        CASE WHEN @columnname = 'Id' AND @direction = 'DESC' THEN B.Id END DESC,
        CASE WHEN @columnname = 'Namesurname' AND @direction = 'ASC' THEN B.Name END ASC,
        CASE WHEN @columnname = 'Namesurname' AND @direction = 'DESC' THEN B.Name END DESC,
		CASE WHEN @columnname = 'Theme' AND @direction = 'ASC' THEN A.FirstName + ' '+A.LastName END ASC,
        CASE WHEN @columnname = 'Theme' AND @direction = 'DESC' THEN A.FirstName + ' '+A.LastName END DESC,
        CASE WHEN @columnname = 'Category' AND @direction = 'ASC' THEN Themes.Name END ASC,
        CASE WHEN @columnname = 'Category' AND @direction = 'DESC' THEN Themes.Name END DESC,
		CASE WHEN @columnname = 'Category' AND @direction = 'ASC' THEN Categories.Name END ASC,
        CASE WHEN @columnname = 'Category' AND @direction = 'DESC' THEN Categories.Name END DESC
END

EXEC task3 'James R. ', 'Groff','Bases of data ','SQL Language','Id','DESC'
--4. SP "Adding a student." SP adds a student and a group. If the group with this name exists, specify the Id of the group in Id_Group. If this name does not exist: first add the group and then the student. Note that the group names are stored in uppercase, but no one guarantees that the user will give the name in uppercase.
--4. SP "Adding a student". SP tələbə və grup əlavə edir. Əgər eyni adlı qrup varsa, bu halda Tələbənin İd_Group sütununa həmin köhnə qrupun İd-si yazılır. Əgər qrup adı yoxdursa onda ilkin olaraq grup daha sonra tələbə əlavə olunur. Əlavə olaraq nəzərə alın ki grup adları UPPERCASE ilə verilənlər bazasında saxlanılır, amma heç kim zəmanət vermir ki, Procedure çağıran şəxs onu UPPERCASE göndərəcək. 

CREATE PROC task4
@firstname NVARCHAR(20),
@lastname NVARCHAR(20),
@term INT,
@groupname NVARCHAR(20),
@idfaculty INT
AS BEGIN
	DECLARE @groupid INT
	SELECT @groupid = G.Id FROM Groups G WHERE G.Name = @groupname
	IF @groupid IS NULL
		BEGIN
			INSERT INTO Groups (Id,Name, Id_Faculty) VALUES (20,UPPER(@groupname),@idfaculty)
			SELECT @groupid = G.Id FROM Groups G WHERE G.Name = UPPER(@groupname)
		END
	INSERT INTO Students (Id,FirstName, LastName, Id_Group, Term) VALUES(101,@firstname, @lastname,@groupid,@term)
END

EXEC task4 'Amin3', 'Aliyev3', 2, '9P10 ',3
--5. SP "Purchase of popular books." SP chooses the top 5 most popular books (among students and teachers simultaneously) and buys another 3 copies of every book.
--5. SP "Purchase of popular books". SP təəbələr və müəlimlər arasında (eyni zamanda) məşhur olan 5 kitabı tapır, və o kitabların hər birindən 3 ədəd alır.

CREATE PROC task5
AS
BEGIN
	UPDATE Books SET Books.Quantity  = Books.Quantity - 3
	FROM (
	SELECT TOP 5 B.Id, COUNT(*) AS [Goturulme sayi] FROM Books B
	LEFT JOIN (SELECT S_Cards.Id_Book FROM S_Cards UNION ALL SELECT T_Cards.Id_Book FROM T_Cards) AS [sm]
	ON sm.Id_Book = B.Id
	GROUP BY B.Id
	ORDER BY COUNT(*) DESC
	) AS [topbook]
	INNER JOIN Books ON Books.Id = topbook.Id
END

EXEC task5
--6. SP "Getting rid of unpopular books." SP chooses top 5 non-popular books and gives half to another educational institution.
--6. SP "Getting rid of unpopular books". SP 5 popular olmayan kitabları seçir və onların yarısını başqa təhsil müəsisəsinə verir.

CREATE PROC task6
AS
BEGIN
	SELECT TOP 5 B.Id, COUNT(*) AS [Goturulme sayi] FROM Books B
	LEFT JOIN (SELECT S_Cards.Id_Book FROM S_Cards UNION ALL SELECT T_Cards.Id_Book FROM T_Cards) AS [sm]
	ON sm.Id_Book = B.Id
	GROUP BY B.Id
	ORDER BY COUNT(*) ASC
END

EXEC task6

--7. SP "A student takes a book." SP gets Id of a student and Id of a book. Check the quantity of books in table Books (if quantity > 0). Check how many books a student has now. If there are 3-4 books, then we issue a warning, and if there are already 5 books, then we do not give him a new book. If a student can take this book, then add rows in table S_Cards and update column quantity in table Books.

CREATE PROC task7
@bookid INT,
@studentid INT
AS BEGIN
	DECLARE @quantity_book INT = 0
	DECLARE @issued_books_student INT = 0
	SELECT @quantity_book = COUNT(*) FROM Books WHERE Books.Id = @bookid
	IF @quantity_book > 0
		BEGIN
			SELECT @issued_books_student = COUNT(*) FROM Students S INNER JOIN S_Cards ON S_Cards.Id_Student = S.Id GROUP BY S.Id ORDER BY S.Id 
			IF @issued_books_student >= 4
				PRINT('Bu sagirdin qaytarilmamis cox kitabi var ve indi bu kitabi goture bilmez')
			ELSE
				BEGIN 
					INSERT INTO S_Cards (Id,Id_Student,Id_Book,DateOut,DateIn,Id_Lib) VALUES (200,@studentid,@bookid,GETDATE(),NULL,2)
					UPDATE Books SET Books.Quantity -= 1 WHERE Books.Id = @bookid
				END
		END
END

EXEC task7 2,2
--8. SP "Teacher takes the book."

CREATE PROC task8
@bookid INT,
@teacherid INT
AS BEGIN
	DECLARE @quantity_book INT = 0
	DECLARE @issued_books_teacher INT = 0
	SELECT @quantity_book = COUNT(*) FROM Books WHERE Books.Id = @bookid
	IF @quantity_book > 0
		BEGIN
			SELECT @issued_books_teacher = COUNT(*) FROM Teachers T INNER JOIN S_Cards ON S_Cards.Id_Student = T.Id GROUP BY T.Id ORDER BY T.Id 
			IF @issued_books_teacher >= 4
				PRINT('Bu muellimin qaytarilmamis cox kitabi var ve indi bu kitabi goture bilmez')
			ELSE
				BEGIN 
					INSERT INTO T_Cards(Id,Id_Teacher,Id_Book,DateOut,DateIn,Id_Lib) VALUES (200,@teacherid,@bookid,GETDATE(),NULL,2)
					UPDATE Books SET Books.Quantity -= 1 WHERE Books.Id = @bookid
				END
		END
END

EXEC task8 2,2

--9. SP "The student returns the book." SP receives Student's Id and Book's Id. In the table S_Cards information is entered about the return of the book. Also you need to add quantity in table Books. If the student has kept the book for more than a year, then he is fined.

CREATE PROC task9
@id INT,
@bookid INT
AS
BEGIN
	DECLARE @Yearkept DATETIME
	SELECT @Yearkept = S_Cards.DateOut FROM S_Cards WHERE S_Cards.Id_Book = @bookid AND S_Cards.Id_Student = @id
	DECLARE @yeardiff INT = DATEDIFF(YEAR, @Yearkept, GETDATE())
	IF(@yeardiff >= 1)
		PRINT('Cerime!')
	UPDATE S_Cards SET DateIn = GETDATE() WHERE Id_Book = @bookid AND Id_Student = @id
	UPDATE Books SET Quantity += 1 WHERE Id = @bookid
END

EXEC task9 2,2
--10. SP "Teacher returns book".

CREATE PROC task10
@id INT,
@bookid INT
AS
BEGIN
	DECLARE @Yearkept DATETIME
	SELECT @Yearkept = T_Cards.DateOut FROM T_Cards WHERE T_Cards.Id_Book = @bookid AND T_Cards.Id_Teacher = @id
	DECLARE @yeardiff INT = DATEDIFF(YEAR, @Yearkept, GETDATE())
	IF(@yeardiff >= 1)
		PRINT('Cerime!')
	UPDATE T_Cards SET DateIn = GETDATE() WHERE Id_Book = @bookid AND Id_Teacher = @id
	UPDATE Books SET Quantity += 1 WHERE Id = @bookid
END

EXEC task10 2,2