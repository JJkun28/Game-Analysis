use game_analysis;
with 
base_stats as (
    select 
        channel, 
        count(distinct user_id) as total_installs,
        sum(activated) as active_users
    from users
    group by channel	
),
revenue_stats as (
    select 
        u.channel, 
        count(distinct ip.user_id) as paying_users,
        sum(ip.amount) as total_revenue,
        sum(case when datediff(date(ip.order_time), u.install_date) between 0 and 6 then ip.amount else 0 end) as revenue_7,
        sum(case when datediff(date(ip.order_time), u.install_date) between 0 and 29 then ip.amount else 0 end) as revenue_30
    from users u 
    left join iap ip on u.user_id = ip.user_id
    group by u.channel
),
recharge_stats as (
    select 
        u.channel, 
        count(distinct case when charge_cnt >= 2 then u.user_id end) as repeat_payers
    from (
        select user_id, count(*) as charge_cnt 
        from iap 
        group by user_id
    ) t
    join users u on t.user_id = u.user_id
    group by u.channel
)
select 
    b.channel as 渠道, 
-- ======================
-- Acuqisition 获客
-- ======================
    b.total_installs as 安装用户数,
    round(b.total_installs *1.0 / (select count(*) from users),4) as 用户占比,

-- ======================
-- Activation 激活
-- ======================
    round(b.active_users*1.0 / b.total_installs, 4) as 激活率,

-- ======================
-- Revenue 变现
-- ======================
    ifnull(rv.paying_users, 0) as 付费用户数,
    
    round(ifnull(rv.paying_users, 0) * 1.0 / b.total_installs, 4) as IPR, 
    round(ifnull(rv.paying_users, 0) * 1.0 / nullif(b.active_users, 0), 4) as APR,
    
    round(ifnull(rv.total_revenue, 0), 2) as 总流水,
    
    round(ifnull(rv.total_revenue, 0) / nullif(rv.paying_users, 0), 2) as ARPPU,
    
    round(ifnull(rv.total_revenue, 0) / nullif(b.total_installs, 0), 2) as ARPU,

    round(ifnull(rv.revenue_7, 0) / b.total_installs, 4) as LTV_7,   
    round(ifnull(rv.revenue_30, 0) / b.total_installs, 4) as LTV_30,
   
    round(ifnull(rp.repeat_payers, 0) * 1.0 / nullif(rv.paying_users, 0), 4) as 复充率

from base_stats b 
left join revenue_stats rv on b.channel = rv.channel
left join recharge_stats rp on b.channel = rp.channel;


-- ======================
-- Retention 留存
-- ======================
select 
    u.channel as 渠道, 
    date(u.install_date) as 注册日期, 
    count(distinct u.user_id) as 激活用户数,

    round(count(distinct case when DATEDIFF(ll.login_date, u.install_date) = 1 then ll.user_id end) 
        / count(distinct u.user_id), 4) as 次日留存率,

    round(count(distinct case when DATEDIFF(ll.login_date, u.install_date) = 7 then ll.user_id end) 
        / count(distinct u.user_id), 4) as 7日留存率,

    round(count(distinct case when DATEDIFF(ll.login_date, u.install_date) = 30 then ll.user_id end) 
        / count(distinct u.user_id), 4) as 30日留存率

from users u 
left join login_log ll on u.user_id = ll.user_id
where u.activated = 1
group by u.install_date, u.channel
order by u.install_date asc;


-- ======================
-- Referral 传播
-- ======================
select
    count(case when channel = 'Friend_referral' then user_id end) as 裂变新增用户,
 
    round(
        count(case when channel = 'Friend_referral' then user_id end) * 1.0 
        / 
        nullif((count(distinct user_id) - count(case when channel = 'Friend_referral' then user_id end)), 0)
    , 4) as 自然增益系数,
    round(count(case when channel = 'Friend_referral' then user_id end)/count(distinct inviter_id),2) as 人均拉新
from users;