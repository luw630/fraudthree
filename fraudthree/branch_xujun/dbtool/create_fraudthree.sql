create database if not exists #DB#;
use #DB#;
set names utf8;
#创建角色账号表  insert  
create table if not exists role_auth(
                                        uid int(11) NOT NULL DEFAULT '0' comment '账号id',
                                        rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                        create_time int(11) NOT NULL DEFAULT '0' comment '创建时间',
                                        update_time timestamp on update current_timestamp default current_timestamp comment '创建时间',
                                        primary key(uid)
                                    )engine = InnoDB, charset = utf8;
#创建玩家基本信息表 insert update
create table if not exists role_info(
                                          rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                          rolename varchar(128) not null DEFAULT '' comment '角色名称',
                                          logo varchar(512) not null DEFAULT '' comment 'logo url',
                                          country varchar(128) not null DEFAULT '' comment '国家',
                                          province varchar(128) not null DEFAULT '' comment '省',
                                          phone varchar(24) not null DEFAULT '' comment '手机号',
                                          sex int(11) NOT NULL DEFAULT '0' comment '性别',
                                          update_time timestamp on update current_timestamp default current_timestamp,
                                          primary key(rid) 
                                    )engine = InnoDB, charset = utf8;
#创建玩家玩棋数据表    insert update                                                                                       
create table if not exists role_playgame(
                                            rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                            offlinenum int(11) NOT NULL DEFAULT '0' comment '级位',   
                                            winnum int(11) NOT NULL DEFAULT '0' comment '胜局', 
                                            losenum int(11) NOT NULL DEFAULT '0' comment '败局', 
                                            continuewinnum  int(11) NOT NULL DEFAULT '0' comment '最大连胜', 
                                            laststatus  int(11) NOT NULL DEFAULT '0' comment '上局结果', 
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(rid) 
                                        )engine = InnoDB, charset = utf8;
#创建玩家金币数据表 insert update
create table if not exists role_money(
                                        rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                        coin bigint unsigned not null DEFAULT '0' comment '金币',
                                        maxcoin bigint unsigned not null DEFAULT '0' comment '历史最大金币',
                                        update_time timestamp on update current_timestamp default current_timestamp,
                                        primary key(rid) 
                                    )engine = InnoDB, charset = utf8;

#创建玩家在线数据表    insert update                                                                                       
create table if not exists role_online(
                                            rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                            activetime int(11) NOT NULL DEFAULT '0', 
                                            onlinetime int(11) NOT NULL DEFAULT '0' comment '上线时间',
                                            roomsvr_id varchar(126) NOT NULL DEFAULT '',
                                            roomsvr_table_id int(11) NOT NULL DEFAULT '0',
                                            roomsvr_table_address int(11) NOT NULL DEFAULT '0',
                                            gatesvr_ip varchar(64) NOT NULL DEFAULT '',
                                            gatesvr_port int(11) NOT NULL DEFAULT '0',
                                            gatesvr_id varchar(126) NOT NULL DEFAULT '',
                                            gatesvr_service_address int(11) NOT NULL DEFAULT '0',
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(rid) 
                                        )engine = InnoDB, charset = utf8;

#创建玩家邮件表 insert delete
create table if not exists role_mailinfos(
                                            mail_key varchar(30) not null default "" comment '邮件key',
                                            rid int(11) not null comment '角色id',
                                            create_time int(11) not null DEFAULT '0' comment '创建时间',
                                            isattach int(11) not NULL DEFAULT '0' comment '是否有附件',
                                            content varchar(1024) not null DEFAULT '' comment '邮件内容json格式',
                                            reason int(11) not null DEFAULT '0' comment '发放邮件的原因',
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(mail_key)
                                        ) engine = InnoDB, charset = utf8;


#牌局记录表 玩家ID 牌局拿牌时间 牌形记录 桌友记录 --------xj
create table if not exists role_resultinfos(
                                            result_key bigint not null AUTO_INCREMENT,
                                            rid int(11) not null comment '角色id',
                                            creator_name varchar(30) NOT NULL DEFAULT '' comment '创建者名称',
                                            room_type  int(11) not null DEFAULT '3' comment '房间类型', 
                                            create_time int(11) not null DEFAULT '0' comment '创建时间',
                                            players_name_coin_winlose TEXT comment '玩家名字和代入筹码和输赢量',
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(result_key) 
                                        )engine = InnoDB, charset = utf8; 
#----------------------------------------------------------xj
