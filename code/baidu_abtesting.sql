use game_analysis;
WITH experiment_users AS (
    SELECT 
        u.user_id,
        u.ab_group, -- 'Control' or 'Treatment'
        u.install_date,
        MAX(CASE WHEN o.order_time <= DATE_ADD(u.install_date, INTERVAL 14 DAY) THEN 1 ELSE 0 END) as is_converted,
        SUM(CASE WHEN o.order_time <= DATE_ADD(u.install_date, INTERVAL 14 DAY) THEN o.amount ELSE 0 END) as user_ltv_14
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id
    WHERE u.channel = 'Baidu_SEM' 
      AND u.install_date BETWEEN '2025-05-01' AND '2025-05-14'
    GROUP BY u.user_id,
        u.ab_group,
        u.install_date
)
SELECT 
    ab_group,
    COUNT(user_id) as sample_size,
    AVG(is_converted) as ipr,
    AVG(user_ltv_14) as avg_arpu_14,
    SUM(user_ltv_14) / NULLIF(SUM(is_converted), 0) as avg_arppu_14 
FROM experiment_users
GROUP BY ab_group;