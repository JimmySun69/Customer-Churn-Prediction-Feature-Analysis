DROP TABLE gathers_users;
CREATE TABLE gathers_users 
AS 
SELECT uid,user_id,MIN(addtime) AS addtime,
SUM(CASE WHEN leixing=1 THEN total_price ELSE 0 END) AS jianli_totalprice,
SUM(CASE WHEN leixing=2 THEN total_price ELSE 0 END) AS heika_totalprice,
SUM(CASE WHEN leixing=3 THEN total_price ELSE 0 END) AS tuangou_totalprice,
MIN(min_buy_time) AS min_buy_time,
MAX(max_buy_time) AS max_buy_time,
SUM(order_count) AS order_count,
SUM(total_price) AS total_price
FROM
(
	-- DEPARTMENT 1
	SELECT xa.*,xb.total_price,xb.order_count,xb.min_buy_time, xb.max_buy_time
	FROM
	(
		SELECT za.uid,zb.user_id,1 AS leixing,to_timestamp(CASE WHEN za.addtime IS NOT NULL THEN za.addtime ELSE zb.jointime END) AS addtime
		FROM 
		public.member_info AS za
		FULL JOIN 
		(
				SELECT ta.*,tb.jointime
				FROM
				(
					SELECT user_id,unionid 
					FROM public.fa_shopro_user_oauth WHERE user_id>0
					GROUP BY 1,2
				) AS ta
				INNER JOIN public.fa_user AS tb ON ta.user_id=tb.id
		) AS zb ON za.unionid =zb.unionid
	) AS xa
	LEFT JOIN 
	(
		SELECT uid,SUM(totalprice) AS total_price,MIN(addtime) AS min_buy_time,COUNT(*) AS order_count,MAX(addtime) AS max_buy_time
		FROM mid.jl_order
		WHERE effectorder='有效订单' AND businesstype IN ('全程','陪签')
		GROUP BY 1
	) AS xb ON xa.uid=xb.uid
	UNION ALL
	--DEPARTMENT 2
	SELECT xa.*,xb.total_price,xb.order_count,xb.min_buy_time,xb.max_buy_time
	FROM
	(
		SELECT za.uid,zb.user_id,2 AS leixing,to_timestamp(CASE WHEN za.addtime IS NOT NULL THEN za.addtime ELSE zb.jointime END) AS addtime
		FROM 
		public.member_info AS za
		FULL JOIN 
		(
				SELECT ta.*,tb.jointime
				FROM
				(
					SELECT user_id,unionid 
					FROM public.fa_shopro_user_oauth WHERE user_id>0
					GROUP BY 1,2
				) AS ta
				INNER JOIN public.fa_user AS tb ON ta.user_id=tb.id
		) AS zb ON za.unionid =zb.unionid
	) AS xa
	LEFT JOIN 
	(
	SELECT uid,SUM(xfcost) AS total_price,MIN(addtime) AS min_buy_time,count(*) AS order_count, MAX(addtime) AS max_buy_time
	FROM
	mid.zhucai_order_commission
	WHERE check_status=1
	GROUP BY 1
	) AS xb ON xa.uid=xb.uid 
	--DEPARTMENT 3
	UNION ALL
	SELECT xa.*,xb.total_price,xb.order_count,xb.min_buy_time,xb.max_buy_time
	FROM
	(
		SELECT za.uid,zb.user_id,3 AS leixing,to_timestamp(CASE WHEN za.addtime IS NOT NULL THEN za.addtime ELSE zb.jointime END) AS addtime
		FROM 
		public.member_info AS za
		FULL JOIN 
		(
				SELECT ta.*,tb.jointime
				FROM
				(
					SELECT user_id,unionid 
					FROM public.fa_shopro_user_oauth WHERE user_id>0
					GROUP BY 1,2
				) AS ta
				INNER JOIN public.fa_user AS tb ON ta.user_id=tb.id
		) AS zb ON za.unionid =zb.unionid
	) AS xa
	LEFT JOIN 
	(
		SELECT user_id,SUM(pay_fee) AS total_price,to_char(to_timestamp(MIN(paytime)),'yyyy-mm-dd hh:ii:ss') AS min_buy_time,count(*) AS order_count, 
					 to_char(to_timestamp(MAX(paytime)),'yyyy-mm-dd hh:ii:ss') AS max_buy_time
		FROM mid.onlinedeal_order_base 
		WHERE status>0
		GROUP BY 1
	)
	AS xb ON xa.user_id=xb.user_id
) AS ca
GROUP BY 1,2
HAVING SUM(total_price)>0;
	
-- Adding city name, city id, username
ALTER TABLE gathers_users ADD city_name VARCHAR(30) DEFAULT '';
ALTER TABLE gathers_users ADD city_id VARCHAR(10) DEFAULT ''; 
ALTER TABLE gathers_users ADD full_name VARCHAR(50) DEFAULT ''; 


-- Retrieving city name from Department 1 and Department 2

UPDATE gathers_users AS za SET city_name=zb.cityname,city_id=zb.cityid
FROM
(
	SELECT ta.uid,tb.cityname,tb.cityid FROM 
	member_info AS ta
	INNER JOIN config_city AS tb ON ta.cityid=tb.cityid
) AS zb
WHERE za.uid=zb.uid;

-- Retrieving city name from Department 3

UPDATE gathers_users AS za SET city_name=zb.city_name,city_id=zb.cityid
FROM
(
	SELECT xa.user_id,REPLACE(xa.city_name, '市', '') AS city_name,xc.cityid
	FROM
	fa_shopro_order AS xa
	INNER JOIN
	(
	SELECT user_id,MAX(createtime) AS createtime 
	FROM fa_shopro_order
	GROUP BY 1
	) AS xb ON xa.user_id=xb.user_id AND xa.createtime = xb.createtime
	LEFT JOIN config_city AS xc ON REPLACE(xa.city_name, '市', '')=xc.cityname
) AS zb
WHERE za.user_id=zb.user_id AND (za.city_name IS NULL OR za.city_name='');

-- Retrieving the Username from Department 1 and Department 2

UPDATE gathers_users AS za SET full_name=zb.fullname
FROM
(
	SELECT xa.uid,xa.fullname
	FROM jl_order AS xa
	INNER JOIN
	(
		SELECT uid,MAX(id) AS id 
		FROM jl_order AS ta
		GROUP BY 1
	) AS xb ON xa.id=xb.id
) AS zb
WHERE za.uid=zb.uid;

-- Retrieving the Username from Department 3

UPDATE gathers_users AS za SET full_name=zb.consignee
FROM
(
	SELECT xa.user_id,xa.consignee
	FROM
	fa_shopro_order AS xa
	INNER JOIN
	(
	SELECT user_id,MAX(createtime) AS createtime 
	FROM fa_shopro_order
	GROUP BY 1
	) AS xb ON xa.user_id=xb.user_id AND xa.createtime = xb.createtime
) AS zb
WHERE za.user_id=zb.user_id AND (za.full_name IS NULL OR za.full_name='');

-- Getting the gender

ALTER TABLE gathers_users ADD gender int DEFAULT NULL;

UPDATE gathers_users AS za SET gender = sex
FROM
(
	SELECT DISTINCT user_id,sex 
	FROM fa_shopro_user_oauth
	WHERE (sex = 1 OR sex = 2) AND user_id <> 0
) AS zb
WHERE za.user_id=zb.user_id;

UPDATE gathers_users AS za SET gender = sex
FROM
(
	SELECT uid,sex
	FROM member_info
	WHERE sex=1 OR sex = 2
) AS zb
WHERE za.uid=zb.uid;

-- Calculating the grand total for refund

ALTER TABLE gathers_users ADD refund_fee int DEFAULT 0; 

-- Adding the refund fee from Department 1

UPDATE gathers_users AS za SET refund_fee = za.refund_fee + zb.refund_total
FROM
(
	SELECT tb.user_id, SUM(tb.refund_fee) AS refund_total
	FROM fa_shopro_order AS ta
	INNER JOIN fa_shopro_order_item AS tb
	ON ta.id = tb.order_id
	WHERE ta.status>0 AND tb.refund_status > 1
	GROUP BY 1
) AS zb
WHERE za.user_id=zb.user_id;

-- Adding the refund fee from Department 2

UPDATE gathers_users AS za SET refund_fee = za.refund_fee + zb.refund_total
FROM
(
	SELECT uid, round(refund_total/100::numeric,0) AS refund_total
	FROM
	(
	SELECT uid, SUM(to_number(refundamount,'9999999999999')) AS refund_total
	FROM jl_order WHERE refundamount > 0
	GROUP BY 1
	) AS tt
) AS zb
WHERE za.uid=zb.uid;

-- Adding the refund fee from Department 3

UPDATE gathers_users AS za SET refund_fee = za.refund_fee + zb.refund_fee
FROM
(
	SELECT tb.uid, SUM(tb.xfcost) AS refund_fee
	FROM t_order_return_info AS ta
	LEFT JOIN t_order_underline AS tb 
	ON ta.order_id =tb.id 
	WHERE ta.status =36
	GROUP BY 1
) AS zb
WHERE za.uid=zb.uid;

-- Those who did not make a purchase after 2020-5-1 are considered as churn user

ALTER TABLE gathers_users ADD churn int DEFAULT 0; 

UPDATE gathers_users AS za SET chrun = 1
FROM
(
	SELECT uid
	FROM gathers_users
	WHERE max_buy_time < '2020-5-1'
) AS zb
WHERE za.uid=zb.uid;

-- Getting the lastest timestamp as one of the import features

ALTER TABLE gathers_users ADD latest_timestamp int DEFAULT NULL; 

UPDATE gathers_users AS za SET latest_timestamp = latest_time
FROM
(
	SELECT user_id,uid,EXTRACT(epoch FROM CAST(max_buy_time AS TIMESTAMP)) AS latest_time
	FROM gathers_users
) AS zb
WHERE za.user_id=zb.user_id;

UPDATE gathers_users AS za SET latest_timestamp = latest_time
FROM
(
	SELECT user_id,uid,EXTRACT(epoch FROM CAST(max_buy_time AS TIMESTAMP)) AS latest_time
	FROM gathers_users
) AS zb
WHERE za.uid=zb.uid;



----------------------------------------------------------------------QUERY--------------------------------------------------------------------------------------

-- Data Query
-- Getting total price from 3 different departments
-- Getting the grand total of the sales
-- To incease the variety of the data input for the model, getting features like gender, lastest time for purchase, city, number of order, refund fee
-- And most importantly, the dependant variable --> churn
-- NOTE THAT -> the churn is decided by those who did not make a purchase after 2020-5-1

SELECT jianli_totalprice AS supervision_total, heika_totalprice AS blackcard_total, tuangou_totalprice AS ecommerce_total,
			 order_count, total_price, city_id, gender, refund_fee, latest_timestamp AS last_buytime, churn
FROM gathers_users

-----------------------------------------------------------------------END-------------------------------------------------------------------------------------
