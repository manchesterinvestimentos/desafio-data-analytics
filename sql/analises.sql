--View apenas para simplificar o uso de joins nas consultas
--e cálculo do faturamento
CREATE VIEW base_vendas AS
SELECT 
	ve.CLIENTE,
	ve.IDADE,
	ve.ESTADO,
	ve.PRODUTO,
    ve.QUANTIDADE_VENDIDA,
    ve.PRECO_UNITARIO,
    ve.DATA,
    ca.CATEGORIA,
    ve.QUANTIDADE_VENDIDA * ve.PRECO_UNITARIO AS FATURAMENTO
FROM vendas AS ve
LEFT JOIN categoria_produtos AS ca
ON ve.PRODUTO = ca.PRODUTO;

--Aqui o objetivo principal seria ter um contato inicial com a base de dados
--e entendender alguns pontos importante sobre os dados

--1) Perfil demográfico dos clientes
--consulta geral das idades dos clientes
SELECT
	MAX(IDADE) AS IDADE_MAX,
	MIN(IDADE) AS IDADE_MIN,
	AVG(IDADE) AS IDADE_MEDIA
FROM vendas;

--entendimento do número de clientes por estado maior-menor (top10)
SELECT 
	ESTADO,
	COUNT(DISTINCT CLIENTE) AS TOTAL_CLIENTES
FROM vendas
GROUP BY ESTADO
ORDER BY TOTAL_CLIENTES DESC
LIMIT 10;

--2) Performance por categoria (top10 quanto a vendas ou faturamento)
SELECT
	CATEGORIA,
	SUM(QUANTIDADE_VENDIDA) AS TOTAL_VENDAS,
	SUM(FATURAMENTO) AS TOTAL_FATURAMENTO,
	AVG(FATURAMENTO) AS TICKET_MEDIO
FROM base_vendas --já usando a view definida no início
GROUP BY CATEGORIA
ORDER BY TOTAL_VENDAS DESC --ou com faturamento
LIMIT 10;

--3) Sazonalidade
--descrição simples das vendas por mês
SELECT 
	MONTH(DATA) AS MES,
	SUM(FATURAMENTO) AS TOTAL_FATURAMENTO,
	SUM(QUANTIDADE_VENDIDA) AS TOTAL_VENDAS
FROM base_vendas
WHERE YEAR(DATA) >= 2025
GROUP BY MES
ORDER BY MES DESC;

--análise dos meses com maior e menor faturamento
SELECT
	MAX(TOTAL_FATURAMENTO) AS MAX_FATURAMENTO,
	MIN(TOTAL_FATURAMENTO) AS MIN_FATURAMENTO,
	AVG(TOTAL_FATURAMENTO) AS MEDIA_FATURAMENTO
FROM (
    SELECT
        MONTH(DATA) AS MES,
        SUM(FATURAMENTO) AS TOTAL_FATURAMENTO
    FROM base_vendas
    WHERE YEAR(DATA) >= 2025
    GROUP BY MONTH(DATA)
);

--4)Tendência de vendas por região
--analisando a evolução de faturamento, venda, ticket e crescimento 
--por estado no último ano
SELECT
    ESTADO,
    MONTH(DATA) AS MES
    SUM(FATURAMENTO) AS TOTAL_FATURAMENTO,
    SUM(QUANTIDADE_VENDIDA) AS TOTAL_VENDAS,
    AVG(FATURAMENTO) AS TICKET_MEDIO,
FROM base_vendas
WHERE YEAR(DATA) >= 2025
GROUP BY ESTADO, MES
ORDER BY ESTADO, MES;

--5)Relação entre idade e categorias compradas
--cte para definir blocos de faixa etarias
--e agregar o total de vendas por faixa etaria e categoria
WITH vendas_faixa AS (
    SELECT
        CASE
            WHEN IDADE < 25 THEN '18–24'
            WHEN IDADE BETWEEN 25 AND 34 THEN '25–34'
            WHEN IDADE BETWEEN 35 AND 44 THEN '35–44'
            WHEN IDADE BETWEEN 45 AND 54 THEN '45–54'
            ELSE '55+'
        END AS FAIXA_ETARIA,
        CATEGORIA,
        SUM(QUANTIDADE_VENDIDA) AS TOTAL_VENDAS
    FROM base_vendas
    GROUP BY FAIXA_ETARIA, CATEGORIA
);

--usa window fuction RANK() para rankear o numero de vendas de cada categorias
--por faixa etaria
SELECT
    FAIXA_ETARIA,
    CATEGORIA,
    TOTAL_VENDAS,
    RANK() OVER (
        PARTITION BY FAIXA_ETARIA
        ORDER BY TOTAL_VENDAS DESC
    ) AS RANK_CATEGORIA
FROM vendas_faixa
ORDER BY FAIXA_ETARIA, RANK_CATEGORIA;
