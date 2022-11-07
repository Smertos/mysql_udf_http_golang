if [[ $# > 0 ]]; then
    version_info=$(mysql --version)
    if [[ "$version_info" == *"Maria"* ]]; then
        include_dir=$(mariadb_config --include)
    else
        include_dir=$(mysql_config --include)
    fi

    sql_result=$(mysql --user=$1 --password=$2 -s -N -e "SHOW VARIABLES LIKE 'plugin_dir';")
    plugin_dir=$(awk '{ print $2 }' <<< $sql_result)

    export CGO_CFLAGS=$include_dir
    go build -buildmode=c-shared -o ./http.so http.go
    #rm $plugin_dir"http.h"
    
    plugin_path="$plugin_dir"http.so
    sudo cp ./http.so $plugin_path 
    sudo chown root:root $plugin_path
    sudo chmod 755 $plugin_path

    mysql --user=$1 --password=$2 -s -N -e "CREATE OR REPLACE FUNCTION http_help RETURNS STRING SONAME 'http.so';"
    mysql --user=$1 --password=$2 -s -N -e "CREATE OR REPLACE FUNCTION http_raw RETURNS STRING SONAME 'http.so';"
    mysql --user=$1 --password=$2 -s -N -e "CREATE OR REPLACE FUNCTION http_get RETURNS STRING SONAME 'http.so';"
    mysql --user=$1 --password=$2 -s -N -e "CREATE OR REPLACE FUNCTION http_post RETURNS STRING SONAME 'http.so';"

    echo "Install Success"
else
    echo "bash install.sh username password(optional)"
fi

