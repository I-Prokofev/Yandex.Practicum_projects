#1 Посчитать, сколько компаний закрылось?
SELECT COUNT(id)
FROM company
WHERE status='closed';
