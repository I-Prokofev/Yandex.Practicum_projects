--#1 Определим количество закрывшихся компаний:
SELECT COUNT(id)
FROM company
WHERE status='closed';

--#2 Отобразим количество привлечённых средств для новостных компаний США:
SELECT funding_total
FROM company
WHERE category_code='news'
  AND country_code='USA'
ORDER BY funding_total DESC;

--#3 Найдем общую сумму сделок по покупке одних компаний другими в долларах за наличные с 2011 по 2013 год включительно:
SELECT 
    SUM(price_amount)
FROM 
    acquisition
WHERE 
    term_code='cash'
    AND EXTRACT(YEAR FROM CAST(acquired_at AS date)) IN (2011,2012,2013);
    
--#4 Отобразим имя, фамилию и названия аккаунтов людей в твиттере, у которых названия аккаунтов начинаются на 'Silver':
SELECT
    first_name,
    last_name,
    twitter_username
FROM
    people
WHERE
    twitter_username LIKE 'Silver%';

--#5 Отобразим всю информацию о людях, у которых названия аккаунтов в твиттере содержат подстроку 'money', а фамилия начинается на 'K':
SELECT
    *
FROM
    people
WHERE
    twitter_username LIKE '%money%'
    AND last_name LIKE 'K%';

--#6 Для каждой страны отобразим общую сумму привлечённых инвестиций, которые получили компании, зарегистрированные в этой стране:
SELECT
    country_code AS country,
    SUM(funding_total) AS funding_total
FROM company
GROUP BY country_code
ORDER BY funding_total DESC;

--#7 Составим таблицу, в которую войдёт дата проведения раунда, а также минимальное и максимальное значения суммы инвестиций, привлечённых в эту 
-- дату. Оставим в итоговой таблице только те записи, в которых минимальное значение суммы инвестиций не равно нулю и не равно максимальному значению.
SELECT
    funded_at AS round_date,
    MIN(raised_amount) AS min_raised_amount,
    MAX(raised_amount) AS max_raised_amount
FROM
    funding_round
GROUP BY 
    funded_at
HAVING 
    MIN(raised_amount)<>0
    AND MIN(raised_amount)<>MAX(raised_amount);

--#8 Создадим поле с категориями:
--  -для фондов, которые инвестируют в 100 и более компаний, назначим категорию high_activity.
--  -для фондов, которые инвестируют в 20 и более компаний до 100, назначим категорию middle_activity.
--  -если количество инвестируемых компаний фонда не достигает 20, назначим категорию low_activity.
-- Отобразим все поля таблицы fund и новое поле с категориями
SELECT 
    *,
    CASE
        WHEN invested_companies >= 100 THEN 'high_activity'
        WHEN invested_companies >= 20 AND invested_companies < 100 THEN 'middle_activity'
        WHEN invested_companies < 20 THEN 'low_activity'
    END
FROM
    fund;

--#9 Для каждой из категорий, назначенных в предыдущем задании, посчитаtаем округлённое до ближайшего целого числа среднее 
-- количество инвестиционных раундов, в которых фонд принимал участие. Выведем на экран категории и среднее число 
-- инвестиционных раундов, отсортируем таблицу по возрастанию среднего:
SELECT 
    CASE
        WHEN invested_companies>=100 THEN 'high_activity'
        WHEN invested_companies>=20 THEN 'middle_activity'
               ELSE 'low_activity'
        END AS activity,
        ROUND(AVG(investment_rounds)) AS avg_investment_rounds
FROM fund
GROUP BY activity
ORDER By avg_investment_rounds;

--#10 Выгрузим таблицу с десятью самыми активными инвестирующими странами. Активность страны определим по среднему количеству 
-- компаний, в которые инвестируют фонды этой страны. Для каждой страны посчитаем минимальное, максимальное и среднее число 
-- компаний, в которые инвестировали фонды, основанные с 2010 по 2012 год включительно.
-- Исключим из таблицы страны с фондами, у которых минимальное число компаний, получивших инвестиции, равно нулю. 
-- Отсортируем таблицу по среднему количеству компаний от большего к меньшему, а затем по коду страны в лексикографическом порядке:
SELECT 
    country_code,
    MIN(invested_companies) AS min_total_ics,
    AVG(invested_companies) AS avg_total_ics,
    MAX(invested_companies) AS max_total_ics
FROM 
    fund
WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) BETWEEN 2010 AND 2012
GROUP BY country_code
HAVING MIN(invested_companies)<>0
ORDER BY avg_total_ics DESC
LIMIT 10

--#11 Отобразим имя и фамилию всех сотрудников стартапов. Добавим поле с названием учебного заведения, которое окончил сотрудник, 
-- если эта информация известна:
SELECT 
    p.first_name,
    p.last_name,
    e.instituition
FROM people AS p
LEFT OUTER JOIN education AS e ON e.person_id=p.id

--#12 Для каждой компании найдем количество учебных заведений, которые окончили её сотрудники. Выведем название компании и число 
-- уникальных названий учебных заведений. Составим топ-5 компаний по количеству университетов:
SELECT
    c.name,
    COUNT(DISTINCT(e.instituition))
FROM company AS c
INNER JOIN people AS p ON c.id=p.company_id
INNER JOIN education AS e ON p.id=e.person_id
GROUP BY c.name
ORDER BY COUNT(DISTINCT(e.instituition)) DESC
LIMIT 5;

--#13 Составим список с уникальными названиями закрытых компаний, для которых первый раунд финансирования оказался последним:
SELECT 
    DISTINCT(c.name)
FROM company AS c
INNER JOIN funding_round AS fr ON fr.company_id=c.id
WHERE c.id IN (SELECT company_id
        FROM funding_round
        WHERE is_first_round=1 AND is_last_round=1)
        AND c.status='closed'

--#14 Составим список уникальных номеров сотрудников, которые работают в компаниях, отобранных в предыдущем задании:
SELECT 
    id
FROM people
WHERE company_id IN (SELECT 
    DISTINCT(c.id)
FROM company AS c
INNER JOIN funding_round AS fr ON fr.company_id=c.id
WHERE c.id IN (SELECT company_id
        FROM funding_round
        WHERE is_first_round=1 AND is_last_round=1)
        AND c.status='closed')

--#15 Составим таблицу, куда войдут уникальные пары с номерами сотрудников из предыдущего запроса и учебным заведением, 
-- которое окончил сотрудник:
SELECT 
    p.id,
    e.instituition
FROM people AS p
INNER JOIN education AS e ON e.person_id=p.id 
WHERE p.company_id IN (SELECT 
    DISTINCT(c.id)
    FROM company AS c
    INNER JOIN funding_round AS fr ON fr.company_id=c.id
    WHERE c.id IN (SELECT company_id
            FROM funding_round
            WHERE is_first_round=1 AND is_last_round=1)
            AND c.status='closed')
GROUP BY p.id, e.instituition

--#16 Посчитаем количество учебных заведений для каждого сотрудника из предыдущего запроса:
SELECT 
    p.id,
    COUNT(e.instituition)
FROM people AS p
INNER JOIN education AS e ON e.person_id=p.id 
WHERE p.company_id IN (SELECT 
    DISTINCT(c.id)
    FROM company AS c
    INNER JOIN funding_round AS fr ON fr.company_id=c.id
    WHERE c.id IN (SELECT company_id
            FROM funding_round
            WHERE is_first_round=1 AND is_last_round=1)
            AND c.status='closed')
GROUP BY p.id

--#17 Дополним предыдущий запрос и выведем среднее число всех учебных заведений, которые 
-- окончили сотрудники разных компаний. Выведем только одну запись без группировки: 
WITH people_stat AS (SELECT 
        p.id AS ID,
        COUNT(e.instituition) AS sum_instituition
    FROM people AS p
    INNER JOIN education AS e ON e.person_id=p.id 
    WHERE p.company_id IN (SELECT 
        DISTINCT(c.id)
        FROM company AS c
        INNER JOIN funding_round AS fr ON fr.company_id=c.id
        WHERE c.id IN (SELECT company_id
                FROM funding_round
                WHERE is_first_round=1 AND is_last_round=1)
                AND c.status='closed')
    GROUP BY p.id)
    
SELECT 
    AVG(people_stat.sum_instituition)
FROM people_stat

--#18 Выведем среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники Facebook*.
--*(сервис, запрещённый на территории РФ):
WITH people_stat AS (SELECT 
        p.id AS ID,
        COUNT(e.instituition) AS sum_instituition
    FROM people AS p
    INNER JOIN education AS e ON e.person_id=p.id 
    WHERE p.company_id = (SELECT 
        DISTINCT(c.id)
        FROM company AS c
        WHERE c.name='Facebook')
    GROUP BY p.id)
    
SELECT 
    AVG(people_stat.sum_instituition)
FROM people_stat

--#19 Составим таблицу из полей:
-- - name_of_fund — название фонда;
-- - name_of_company — название компании;
-- - amount — сумма инвестиций, которую привлекла компания в раунде.
-- В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов, а раунды финансирования 
-- проходили с 2012 по 2013 год включительно:
SELECT 
    f.name AS name_of_fund,
    c.name AS name_of_company,
    fr.raised_amount AS amount
FROM investment AS i
INNER JOIN company AS c ON i.company_id=c.id
INNER JOIN fund AS f ON i.fund_id=f.id
INNER JOIN funding_round AS fr ON i.funding_round_id=fr.id
WHERE c.milestones>6
    AND EXTRACT(YEAR FROM CAST(fr.funded_at AS date)) BETWEEN 2012 AND 2013

--#20 Выгрузим таблицу, в которой будут следующие поля:
-- - название компании-покупателя;
-- - сумма сделки;
-- - название компании, которую купили;
-- - сумма инвестиций, вложенных в купленную компанию;
-- - доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций, округлённая до ближайшего целого числа.
-- Не будем учитывать те сделки, в которых сумма покупки равна нулю. Если сумма инвестиций в компанию равна нулю, исключим такую компанию из таблицы:
SELECT 
    c_acquiring_company.name AS acquiring_company,
    a.price_amount AS price_amount,
    c_acquired_company.name AS acquired_company,
    c_acquired_company.funding_total AS funding_total,
    ROUND(a.price_amount/c_acquired_company.funding_total) AS share
FROM acquisition AS a
LEFT OUTER JOIN company AS c_acquiring_company ON a.acquiring_company_id=c_acquiring_company.id
LEFT OUTER JOIN company AS c_acquired_company ON a.acquired_company_id=c_acquired_company.id
WHERE 
    c_acquired_company.funding_total<>0
    AND a.price_amount<>0
ORDER BY price_amount DESC, acquired_company
LIMIT 10;

--#21 Выгрузим таблицу, в которую войдут названия компаний из категории social, получившие 
-- финансирование с 2010 по 2013 год включительно. Выведем также номер месяца, в котором проходил раунд финансирования:
SELECT 
    c.name AS company_name,
    EXTRACT(MONTH FROM CAST(fr.funded_at AS date)) AS funded_month
FROM company AS c
INNER JOIN funding_round AS fr ON fr.company_id=c.id 
WHERE 
    c.category_code='social'
    AND EXTRACT(YEAR FROM CAST(fr.funded_at AS date)) BETWEEN 2010 AND 2013

--#22 Отберем данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды. 
-- Сгруппируем данные по номеру месяца и получим таблицу, в которой будут поля:
-- - номер месяца, в котором проходили раунды;
-- - количество уникальных названий фондов из США, которые инвестировали в этом месяце;
-- - количество компаний, купленных за этот месяц;
-- - общая сумма сделок по покупкам в этом месяце:

--фонды из США
WITH usa_funds AS(
    SELECT
        f.id AS fund_id,
        f.name AS fund_name
    FROM fund AS f
    WHERE 
        f.country_code='USA'
),

--количество купленных компаний и общая сумма сделок по месяцам
acq_stat AS (
    SELECT 
        EXTRACT(MONTH FROM CAST(a.acquired_at AS date)) AS month_number,
        COUNT(a.acquired_company_id) AS ac_number,
        SUM(a.price_amount) AS ac_total_sum
    FROM acquisition AS a
    WHERE EXTRACT(YEAR FROM CAST(a.acquired_at AS date)) BETWEEN 2010 AND 2013
    GROUP BY month_number
    ORDER BY month_number
),

f_stat AS (
SELECT 
    EXTRACT(MONTH FROM CAST(fr.funded_at AS date)) AS month_number,
    COUNT(DISTINCT(usa_f.fund_name)) AS unique_names_number
FROM funding_round AS fr
INNER JOIN investment AS i ON i.funding_round_id=fr.id
INNER JOIN usa_funds AS usa_f ON usa_f.fund_id=i.fund_id
WHERE EXTRACT(YEAR FROM CAST(fr.funded_at AS date)) BETWEEN 2010 AND 2013
GROUP BY month_number
ORDER BY month_number
)

SELECT
    f_s.month_number,
    f_s.unique_names_number,
    a_s.ac_number,
    a_s.ac_total_sum
FROM f_stat AS f_s
INNER JOIN acq_stat AS a_s ON a_s.month_number=f_s.month_number

--#23 Составим сводную таблицу и выведем среднюю сумму инвестиций для стран, в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах. 
-- Данные за каждый год включим в отдельное поле. Отсортируем таблицу по среднему значению инвестиций за 2011 год от большего к меньшему:
WITH year_2011 AS(
SELECT
    country_code AS country,
    AVG(funding_total) AS avg_year
FROM company
WHERE EXTRACT(YEAR FROM cast(founded_at AS TIMESTAMP)) = 2011
GROUP BY country_code  
),

year_2012 AS(
SELECT
    country_code AS country,
    AVG(funding_total) AS avg_year
FROM company
WHERE EXTRACT(YEAR FROM cast(founded_at AS TIMESTAMP)) = 2012
GROUP BY country_code  
),

year_2013 AS (
SELECT
    country_code AS country,
    AVG(funding_total) AS avg_year
FROM company
WHERE EXTRACT(YEAR FROM cast(founded_at AS TIMESTAMP)) = 2013
GROUP BY country_code  
)

SELECT
    y2011.country,
    y2011.avg_year AS avg_funding_total_2011,
    y2012.avg_year AS avg_funding_total_2012,
    y2013.avg_year AS avg_funding_total_2013
FROM year_2011 AS y2011
INNER JOIN year_2012 AS y2012 ON y2011.country=y2012.country
INNER JOIN year_2013 AS y2013 ON y2012.country=y2013.country
ORDER BY avg_funding_total_2011 DESC
