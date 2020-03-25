#!/bin/bash
> /tmp/all_Case/test.log

check_clx_db ()
{
 # perform db check
  check_cmd=$(ssh -n karma042 "clx s" | grep "Error connecting to database via" | wc -l)
  if [[ $check_cmd -ne 0 ]]; then
     echo "Database seems down... Trying to get it back online"
     start=$(ssh -n karma042 clx dbrestart)
     while [[ $check_cmd -ne 0 ]]; do
         check_cmd=$(ssh -n karma042 "clx s" | grep "Error connecting to database via" | wc -l)
         sleep 5
     done
    echo "Database up and running... Proceeding now"
  fi
}

check_xpand_instances ()
{
  # perform xpand instance check
  count=$(ps -aef | grep -i mysqld | wc -l)
  if [[ $count -ne 2 ]]; then
       pkill mysqld
       sleep 2
       echo "xpand server not running.. Starting the server"
       /opt/clustrix/clxengine/bin/mysqld --basedir=/opt/clustrix/clxengine/ --datadir=/opt/clustrix/clxengine/data/ --user=mysql --default-storage-engine=xpand --plugin-maturity=experimental --plugin-load "xpand=ha_xpand.so" --xpand_host=karma180,karma042,karma072 --xpand_port=3306 --skip-grant-tables &
      sleep 10
  fi
}

# while loop
while IFS= read -r line; do
  date
  date >> /tmp/all_Case/test.log
  check_clx_db
  check_xpand_instances

python -c "import MySQLdb;db=MySQLdb.connect(host='karma042', user='root', passwd='', db='test');cr=db.cursor(); cr.execute('set names utf8');cr.execute ('SELECT name FROM system.databases WHERE hidden=0 AND name != \'information_schema\' AND name != \'clustrix_statd\''); dblist=cr.fetchall();
for dbname in dblist: cr.execute('drop database \`{}\`'.format(dbname[0]))
cr.execute('create database test')"

  echo executing case "$line"
  echo executing case "$line" >> /tmp/all_Case/test.log
  cd /opt/clustrix/clxengine/mysql-test
  ./mysql-test-run $line --big-test --mysqld=--plugin-maturity=experimental --mysqld=--xpand_hosts=karma180,karma042,karma072 --mysqld=--xpand_port=3306 --mysqld=--plugin-load=xpand=ha_xpand.so --mysqld=--default-storage-engine=xpand --skip-test-list=unstable-tests --mysqld=--binlog-format=statement >> /tmp/all_Case/test.log
  cd - > /dev/null
  date >> /tmp/all_Case/test.log
done < "/tmp/listcases.list"


