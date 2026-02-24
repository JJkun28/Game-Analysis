create database if not exists Game_Analysis;
use Game_Analysis;
create table if not exists Users(
		user_id INT primary key,
		install_date Datetime,
		channel varchar(30),
		inviter_id INT,
		activated INT,
		index idx_install_date (install_date),
		index idx_channel (channel)
);
create table if not exists IAP(
		order_id BIGINT primary key,
		user_id INT,
		order_time datetime,
		amount INT,
		index idx_user_id (user_id)
);
create table if not exists login_log(
		user_id INT,
		login_date datetime,
		primary key (user_id, login_date),
		index idx_login_date (login_date)
);