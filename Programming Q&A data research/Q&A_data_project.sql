-- #1 Найдем количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки»:
WITH question_id AS 
(SELECT id
FROM stackoverflow.post_types
WHERE type = 'Question')

SELECT COUNT(id)
FROM stackoverflow.posts 
WHERE post_type_id = (SELECT id
FROM stackoverflow.post_types
WHERE type = 'Question') AND (score > 300 OR favorites_count >= 100);

--#2 Опредеим, сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно, результат округлим до целого числа:
WITH qc AS 
(SELECT CAST(DATE_TRUNC('day', creation_date) AS date) AS dt,
       COUNT(id) AS questions_cnt
FROM stackoverflow.posts -- название таблицы и условие``
WHERE post_type_id = (SELECT id
FROM stackoverflow.post_types
WHERE type = 'Question') AND (DATE_TRUNC('day', creation_date) BETWEEN '01-11-2008' AND '18-11-2008')
GROUP BY DATE_TRUNC('day', creation_date))

SELECT ROUND(AVG(qc.questions_cnt),0)
FROM qc

--#3 Опредеим количество уникальных пользователей, которые получили значки сразу в день регистрации:
SELECT COUNT(DISTINCT(u.id))
FROM stackoverflow.users u
LEFT JOIN stackoverflow.badges b ON u.id = b.user_id 
WHERE DATE_TRUNC('day', u.creation_date) = DATE_TRUNC('day', b.creation_date);

--#4 Найдем число уникальных постов пользователя с именем Joel Coehoorn, которые получили хотя бы один голос:
SELECT COUNT(DISTINCT(p.id))
FROM stackoverflow.posts p
RIGHT JOIN stackoverflow.votes v ON p.id = v.post_id
WHERE p.user_id = (SELECT id
FROM stackoverflow.users
WHERE display_name = 'Joel Coehoorn');

--#5 Выгрузим все поля таблицы vote_types; добавим к таблице поле rank, в которое войдут номера записей в 
--обратном порядке; таблицу отсортируем по полю id:
SELECT *,
       ROW_NUMBER() OVER (ORDER BY id DESC) AS rank 
FROM stackoverflow.vote_types
ORDER BY id;

--#6 Отберем 10 пользователей, которые поставили больше всего голосов типа Close; отобразим таблицу из 
--двух полей: идентификатором пользователя и количеством голосов; отсортируем данные сначала по убыванию 
--количества голосов, потом по убыванию значения идентификатора пользователя:
SELECT DISTINCT(user_id) AS uid,
       COUNT(post_id) AS votes_cnt
FROM stackoverflow.votes
WHERE vote_type_id = (SELECT id 
FROM stackoverflow.vote_types
WHERE name = 'Close')
GROUP BY uid
ORDER BY votes_cnt DESC, uid DESC
LIMIT 10

--#7 Отберем 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года 
-- включительно. Отобразим следующие поля: 
-- * идентификатор пользователя;
-- * число значков;
-- * место в рейтинге — чем больше значков, тем выше рейтинг. 
-- Пользователям, которые набрали одинаковое количество значков, присвоим одно и то же место в рейтинге. 
--Отсортируем записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя:
WITH b AS 
(SELECT user_id AS uid, 
        COUNT(DISTINCT id) AS badges_cnt       
FROM stackOverflow.badges
WHERE DATE_TRUNC('day', creation_date) BETWEEN '15-11-2008' AND '15-12-2008'
GROUP BY user_id
ORDER BY badges_cnt DESC
LIMIT 10)

SELECT *,
       DENSE_RANK() OVER(ORDER BY badges_cnt DESC)
FROM b
ORDER BY badges_cnt DESC, uid

--#8 Опредеим, сколько в среднем очков получает пост каждого пользователя. Сформируем таблицу из следующих полей:
-- * заголовок поста;
-- * идентификатор пользователя;
-- * число очков поста;
-- * среднее число очков пользователя за пост, округлённое до целого числа. 
-- Не будем учитывать посты без заголовка, а также те, что набрали ноль очков:
SELECT title,
       user_id,
       score,
       ROUND(AVG(score) OVER (PARTITION BY user_id),0) AS avg_score
FROM stackoverflow.posts
WHERE title != '' AND score!=0;

--#9 Отобразим заголовки постов, которые были написаны пользователями, получившими более 1000 значков. 
--Не будем учитыать посты без заголовков: 
WITh top_users AS (SELECT DISTINCT(user_id) AS uid,
       COUNT(id) AS badges_cnt
FROM stackoverflow.badges
GROUP BY user_id
ORDER BY badges_cnt DESC)
                             
SELECT title
FROM stackoverflow.posts
WHERE title != '' AND user_id=(SELECT uid
FROM top_users
WHERE badges_cnt>1000);

--#10 Подготовим запрос, который выгрузит данные о пользователях из США (United States). 
-- Разделим пользователей на три группы в зависимости от количества просмотров их профилей:
-- * пользователям с числом просмотров больше либо равным 350 присвоим группу 1;
-- * пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
-- * пользователям с числом просмотров меньше 100 — группу 3.
-- Отобразим в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. 
-- Не будем включать в итоговую таблицу пользователей с нулевым количеством просмотров:
WITH users_stat AS
(SELECT id AS uid,
        SUM(views) AS total_views
FROM stackoverflow.users
WHERE location LIKE '%United States%'
GROUP BY uid)

SELECT *,
       CASE   
           WHEN total_views < 100 THEN 3
           WHEN total_views < 350 THEN 2
           WHEN total_views >= 350 THEN 1
       END AS group
FROM users_stat
WHERE total_views != 0;

--#11 Дополним предыдущий запрос: отобразим лидеров каждой группы, тех пользователей, которые набрали 
-- максимальное число просмотров в своей группе. Выведем поля с идентификатором пользователя, 
-- группой и количеством просмотров. Отсортируем таблицу по убыванию просмотров, а затем 
-- по возрастанию значения идентификатора:
WITH users_stat AS
(SELECT id AS uid,
        SUM(views) AS total_views
FROM stackoverflow.users
WHERE location LIKE '%United States%'
GROUP BY uid),

users_group AS 
(SELECT *,
       CASE   
           WHEN total_views < 100 THEN 3
           WHEN total_views < 350 THEN 2
           WHEN total_views >= 350 THEN 1
       END AS group_num
FROM users_stat
WHERE total_views != 0),

max_views AS (SELECT DISTINCT(group_num) AS group_num,
       MAX(total_views) AS max_val
FROM users_group
GROUP BY group_num) 

SELECT u_g.uid,
       u_g.group_num,
       u_g.total_views
FROM users_group u_g
JOIN max_views m_v ON u_g.group_num = m_v.group_num
WHERE total_views = max_val
ORDER BY total_views DESC, uid;

--#12 Посчитайем ежедневный прирост новых пользователей в ноябре 2008 года, сформируем таблицу с полями:
-- * номер дня;
-- * число пользователей, зарегистрированных в этот день;
-- * сумму пользователей с накоплением.
SELECT DISTINCT(EXTRACT(DAY FROM creation_date)) AS day_num,
       COUNT(id) AS user_cnt
FROM stackoverflow.users
WHERE CAST(DATE_TRUNC('month', creation_date) AS date) = '01-11-2008'
GROUP BY creation_date;

--#13 Для каждого пользователя, который написал хотя бы один пост, найдем интервал между регистрацией 
-- и временем создания первого поста. Отобразим идентификатор пользователя, разницу во времени между 
-- регистрацией и первым постом.
WITH stat AS 
(SELECT user_id AS uid,
        MIN(creation_date) OVER (PARTITION BY user_id) AS dt
FROM stackoverflow.posts)

SELECT DISTINCT(u.id),
       s.dt - u.creation_date AS diff
FROM stackoverflow.users u
RIGHT JOIN stat s ON u.id = s.uid;

--#14 Выведем общую сумму просмотров постов за каждый месяц 2008 года. Если данных за какой-либо месяц 
-- в базе нет, такой месяц пропустим. Результат отсортируем по убыванию общего количества просмотров:
SELECT CAST(DATE_TRUNC('month', creation_date) AS date) AS dt,
       SUM(views_count) AS total_views
FROM stackoverflow.posts
GROUP BY DATE_TRUNC('month', creation_date)
ORDER BY total_views DESC;

--#15 Выведем имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) 
-- дали больше 100 ответов. Не будем учитывать вопросы, которые задавали пользователи. Для каждого имени пользователя 
-- выведем количество уникальных значений user_id; отсортируем результат по полю с именами в лексикографическом порядке:
SELECT users.display_name, 
       COUNT(DISTINCT posts.user_id) AS t
FROM stackoverflow.users 
JOIN stackoverflow.posts ON posts.user_id = users.id
WHERE posts.post_type_id = 2
AND CAST(posts.creation_date AS date) <= CAST((users.creation_date + INTERVAL '1 month') AS date)
AND DATE_TRUNC('day', posts.creation_date) >= DATE_TRUNC('day', users.creation_date)
GROUP BY users.display_name
HAVING COUNT(posts.id) > 100

--#16 Выведем количество постов за 2008 год по месяцам; отберем посты от пользователей, которые зарегистрировались 
-- в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. Отсортируем таблицу по значению месяца по убыванию:
SELECT CAST(DATE_TRUNC('month', creation_date) AS date) AS dt,
       COUNT(id)
FROM stackoverflow.posts
WHERE (DATE_TRUNC('year', creation_date) = '01-01-2008') AND (user_id IN (SELECT id
FROM stackoverflow.users
WHERE DATE_TRUNC('month', creation_date) = '01-09-2008')) AND (user_id IN (SELECT DISTINCT(user_id)
FROM stackoverflow.posts
WHERE DATE_TRUNC('month', creation_date) = '01-12-2008'))
GROUP BY DATE_TRUNC('month', creation_date)
ORDER BY dt DESC;

--#17 Проанализируем данные о постах и выведем несколько полей:
-- * идентификатор пользователя, который написал пост;
-- * дата создания поста;
-- * количество просмотров у текущего поста;
-- * сумму просмотров постов автора с накоплением.
-- Данные в таблице отсортируемы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе 
-- отсортируем по возрастанию даты создания поста:
SELECT user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER (PARTITION BY user_id ORDER BY id, creation_date)
FROM stackoverflow.posts;

--#18 Опредеим, сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой. 
-- Для каждого пользователя опредеим дни, в которые он или она опубликовали хотя бы один пост. 
-- Выведем результат в виде одно целого числа: 
WITH u_stat AS 
(SELECT user_id,
        COUNT(DISTINCT(DATE_TRUNC('day', creation_date))) AS day_cnt
FROM stackoverflow.posts
WHERE DATE_TRUNC('day', creation_date) BETWEEN '01-12-2008' AND '07-12-2008' GROUP BY user_id)

SELECT ROUND(AVG(u_stat.day_cnt), 0)
FROM u_stat;

--#19 Опредеим, на сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года.
--Отобразим таблицу со следующими полями:
-- * номер месяца;
-- * количество постов за месяц;
-- * процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
-- Если постов стало меньше, значение процента будет отрицательным, если больше — положительным. 
-- Округлим значение процента до двух знаков после запятой:
WITH p_stat AS 
(SELECT EXTRACT(MONTH FROM CAST(creation_date AS date)) AS m_num, 
        COUNT(id) AS posts_cnt
FROM stackoverflow.posts
WHERE DATE_TRUNC('day', creation_date) BETWEEN '01-09-2008' AND '31-12-2008' 
GROUP BY m_num)

SELECT *,
       ROUND((posts_cnt::numeric / LAG(posts_cnt) OVER (ORDER BY m_num) -1)*100, 2) AS diff
FROM p_stat;

--#20 Выгрузим данные активности пользователя, который опубликовал больше всего постов за всё время. 
-- Выведите данные за октябрь 2008 года в следующем виде:
-- * номер недели;
-- * дата и время последнего поста, опубликованного на этой неделе.
WITH user_stat AS 
(SELECT EXTRACT(WEEK FROM creation_date) AS week_num, 
       creation_date
FROM stackoverflow.posts
WHERE user_id = (SELECT user_id
FROM stackoverflow.posts
GROUP BY user_id
ORDER BY COUNT(id) DESC
LIMIT 1) AND DATE_TRUNC('month', creation_date) = '01-10-2008')

SELECT DISTINCT(week_num),
       MAX(creation_date) OVER (PARTITION BY week_num) AS dt
FROM user_stat
ORDER BY week_num;