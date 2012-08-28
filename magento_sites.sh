#!/bin/bash

SITES_DIR="/Users/david/Sites/"
SAMPLE_DATA_VERSION="1.6.1.0"
MAGENTO_VERSIONS_ARRAY=("1.4.0.1" "1.4.1.0" "1.4.1.1" "1.4.2.0" "1.5.0.1" "1.5.1.0" "1.6.0.0" "1.6.1.0" "1.6.2.0" "1.7.0.0" "1.7.0.2")
MAGENTO_SAFE_VERSIONS_ARRAY=( "${MAGENTO_VERSIONS_ARRAY[@]//./}" )
PHP_PATH="/Applications/MAMP/bin/php/php5.3.6/bin/php"
SQL_PATH="/Applications/MAMP/Library/bin/mysql"

echo -n "Downloading and Extracting Sample Data..."
if [ -f $SITES_DIR"magento-sample-data-$SAMPLE_DATA_VERSION.tar.bz2" ]
    then
        echo "  Already exists"
    else
        curl www.magentocommerce.com/downloads/assets/$SAMPLE_DATA_VERSION/magento-sample-data-$SAMPLE_DATA_VERSION.tar.bz2 > $SITES_DIR"magento-sample-data-$SAMPLE_DATA_VERSION.tar.bz2"
fi
tar xzf $SITES_DIR"magento-sample-data-$SAMPLE_DATA_VERSION.tar.bz2" -C $SITES_DIR

echo "Downloading Magento Archives..."
for i in "${MAGENTO_VERSIONS_ARRAY[@]}"
do
    echo -n "    Downloading $i..."
    if [ -f $SITES_DIR"magento-$i.tar.bz2" ]
        then
            echo "  Already exists"
        else
        curl www.magentocommerce.com/downloads/assets/$i/magento-$i.tar.bz2 > $SITES_DIR"magento-$i.tar.bz2"
        echo "    Done"
    fi
done

echo "Extracting Magento Archives..."
for i in "${MAGENTO_VERSIONS_ARRAY[@]}"
do
    echo -n "    Extracting $i Archive..."
    tar xzf $SITES_DIR"magento-$i.tar.bz2" -C $SITES_DIR
    rm -fr $SITES_DIR"magento_$i"
    mv $SITES_DIR"magento/" $SITES_DIR"magento_$i/"
    rm -fr $SITES_DIR"magento"
    echo "    Done"
done

echo "Creating Magento Databases..."
for i in "${MAGENTO_SAFE_VERSIONS_ARRAY[@]}"
do
    echo -e "    Creating Database for $i..."
    $SQL_PATH -uroot -proot -e "DROP DATABASE IF EXISTS magento_$i;"
    $SQL_PATH -uroot -proot -e "CREATE DATABASE magento_$i;"
    echo "    Done"
done

echo "Importing Sample Data..."
echo "    1 of 2 Starting Filesystem Import..."
for i in "${MAGENTO_VERSIONS_ARRAY[@]}"
do
    echo -e "        Copying Files for $i..."
    cp -R $SITES_DIR"magento-sample-data-1.6.1.0/media/catalog/" $SITES_DIR"magento_$i/media/"
    echo "        Done"
done
echo "    1 of 1 Filesystem Done"
echo "    2 of 2 Starting Database Import..."
for i in "${MAGENTO_SAFE_VERSIONS_ARRAY[@]}"
do
    echo -e "        Importing Database for $i..."
    $SQL_PATH -uroot -proot magento_$i < $SITES_DIR"magento-sample-data-$SAMPLE_DATA_VERSION/magento_sample_data_for_$SAMPLE_DATA_VERSION.sql"
    echo "      Done"
done
echo "    2 of 2 Database Import Done"

echo "Deleting Sample Data Folder..."
rm -fr $SITES_DIR"magento-sample-data-$SAMPLE_DATA_VERSION"
echo "Deleted"

echo "Correcting Folder Permissions..."
for i in "${MAGENTO_VERSIONS_ARRAY[@]}"
do
    mkdir $SITES_DIR"magento_$i/var/cache/"
    chmod 777 $SITES_DIR"magento_$i"
    chmod -R 777 $SITES_DIR"magento_$i/media" $SITES_DIR"magento_$i/var"
    echo "  $i Done"
done

echo "Installing Magento..."
for (( i = 0 ; i < ${#MAGENTO_VERSIONS_ARRAY[@]} ; i++ ))
do
    echo "    Installing ${MAGENTO_VERSIONS_ARRAY[$i]}..."
    $PHP_PATH -f $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/install.php" -- \
    --license_agreement_accepted "yes" \
    --locale "en_GB" \
    --timezone "Europe/London" \
    --default_currency "GBP" \
    --db_host "/Applications/MAMP/tmp/mysql/mysql.sock" \
    --db_name "magento_${MAGENTO_SAFE_VERSIONS_ARRAY[$i]}" \
    --db_user "root" \
    --db_pass "root" \
    --url "http://${MAGENTO_SAFE_VERSIONS_ARRAY[$i]}.magento.com/" \
    --skip_url_validation  "yes" \
    --use_rewrites "yes" \
    --use_secure "no" \
    --secure_base_url "https://${MAGENTO_SAFE_VERSIONS_ARRAY[$i]}.magento.com/" \
    --use_secure_admin "no" \
    --admin_firstname "--firstname" \
    --admin_lastname "--lastname" \
    --admin_email "example@example.com" \
    --admin_username "example@example.com" \
    --admin_password "password123"
done