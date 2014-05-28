#!/bin/bash

SITES_DIR="/Users/david/Sites/magento/"
# SAMPLE_DATA_VERSION="1.6.1.0"
SAMPLE_DATA_VERSION="1.9.0.0"
# MAGENTO_VERSIONS_ARRAY=("1.4.0.1" "1.4.1.0" "1.4.1.1" "1.4.2.0" "1.5.0.1" "1.5.1.0" "1.6.0.0" "1.6.1.0" "1.6.2.0" "1.7.0.0" "1.7.0.2" "1.8.0.0" "1.8.1.0")
MAGENTO_VERSIONS_ARRAY=("1.9.0.1")
MAGENTO_SAFE_VERSIONS_ARRAY=( "${MAGENTO_VERSIONS_ARRAY[@]//./}" )
PHP_PATH="/Applications/MAMP/bin/php/php5.4.4/bin/php"
SQL_PATH="/Applications/MAMP/Library/bin/mysql"
SBP_PATH="/Users/david/Sites/github/Magento-Boilerplate"
MYSQL_USER="root"
MYSQL_PASS="root"

function remove_all_installs {

    echo "Removing all magento installs..."
    echo "  Removing files and directories..."
    for i in "${MAGENTO_VERSIONS_ARRAY[@]}"
    do
        echo -n "    Removing $i..."
        rm -fr $SITES_DIR"magento_$i"
        echo "done"
    done
    echo "  Removing databases..."
    for i in "${MAGENTO_SAFE_VERSIONS_ARRAY[@]}"
    do
        echo -n "       Deleting $i database..."
        $SQL_PATH -u$MYSQL_USER -p$MYSQL_PASS -e "DROP DATABASE IF EXISTS magento_$i;"
        echo "done"
    done
    echo "Romeo...done."

}

function install_all_versions {

    echo "Install Sample Data? (y/n)"
    read INSTALL_SAMPLE_DATA
    if [ $INSTALL_SAMPLE_DATA == 'y' ]; then
        echo -n "Downloading and Extracting Sample Data..."
        if [ -f $SITES_DIR"magento-sample-data-$SAMPLE_DATA_VERSION.tar.bz2" ]
            then
                echo "already exists"
            else
                curl www.magentocommerce.com/downloads/assets/$SAMPLE_DATA_VERSION/magento-sample-data-$SAMPLE_DATA_VERSION.tar.bz2 > $SITES_DIR"magento-sample-data-$SAMPLE_DATA_VERSION.tar.bz2"
        fi
        tar xzf $SITES_DIR"magento-sample-data-$SAMPLE_DATA_VERSION.tar.bz2" -C $SITES_DIR
    else
        echo "Skipping Sample Data Download"
    fi

    echo "Downloading Magento Archives..."
    for i in "${MAGENTO_VERSIONS_ARRAY[@]}"
    do
        echo -n "    Downloading $i..."
        if [ -f $SITES_DIR"magento-$i.tar.bz2" ]
            then
                echo "already exists"
            else
            curl www.magentocommerce.com/downloads/assets/$i/magento-$i.tar.bz2 > $SITES_DIR"magento-$i.tar.bz2"
            echo "done"
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
        echo "done"
    done

    echo "Creating Magento Databases..."
    for i in "${MAGENTO_SAFE_VERSIONS_ARRAY[@]}"
    do
        echo -n "    Creating Database for $i..."
        $SQL_PATH -u$MYSQL_USER -p$MYSQL_PASS -e "DROP DATABASE IF EXISTS magento_$i;"
        $SQL_PATH -u$MYSQL_USER -p$MYSQL_PASS -e "CREATE DATABASE magento_$i;"
        echo "done"
    done

    if [ $INSTALL_SAMPLE_DATA == 'y' ]; then
        echo "Importing Filesystem and Database Sample Data..."
        echo "    Starting Filesystem Import..."
        for i in "${MAGENTO_VERSIONS_ARRAY[@]}"
        do
            echo -n "        Copying Files for $i..."
            cp -R $SITES_DIR"magento-sample-data-$SAMPLE_DATA_VERSION/" $SITES_DIR"magento_$i/"
            echo "done"
        done
        echo "    Filesystem Done"
        echo "    Starting Database Import..."
        for i in "${MAGENTO_SAFE_VERSIONS_ARRAY[@]}"
        do
            echo -n "        Importing Database for $i..."
            $SQL_PATH -u$MYSQL_USER -p$MYSQL_PASS magento_$i < $SITES_DIR"magento-sample-data-$SAMPLE_DATA_VERSION/magento_sample_data_for_$SAMPLE_DATA_VERSION.sql"
            echo "done"
        done
        echo "    Database Import Done"
        echo -n "Deleting Sample Data Folder..."
        rm -fr $SITES_DIR"magento-sample-data-$SAMPLE_DATA_VERSION"
        echo "done"
    else
        echo "Skipping Sample Data Installation"
    fi

    echo "Correcting Folder Permissions..."
    for i in "${MAGENTO_VERSIONS_ARRAY[@]}"
    do
        mkdir $SITES_DIR"magento_$i/var/cache/"
        chmod 777 $SITES_DIR"magento_$i"
        chmod -R 777 $SITES_DIR"magento_$i/includes" $SITES_DIR"magento_$i/media" $SITES_DIR"magento_$i/var" $SITES_DIR"magento_$i/app/etc"
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

    echo "Install SMBP? (y/n)"
    read INSTALL_SMBP
    if [ $INSTALL_SMBP == 'y' ]; then
        echo "Installing Skywire Boilerplate from '$SBP_PATH'..."
        for (( i = 0 ; i < ${#MAGENTO_VERSIONS_ARRAY[@]} ; i++ ))
        do
            echo -n "    Copying files for ${MAGENTO_VERSIONS_ARRAY[$i]}..."
            cp -R $SBP_PATH/ $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/"
            rm -fr $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/app/design/frontend/skywire/"
            rm -fr $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/skin/frontend/skywire/"
            ln -s $SBP_PATH"/app/design/frontend/skywire/" $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/app/design/frontend/skywire"
            ln -s $SBP_PATH"/skin/frontend/skywire/" $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/skin/frontend/skywire"
            cp -R "/Users/david/Sites/github/Magento-Extensions/CmsLayouts/src/" $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/"
            cp -R "/Users/david/Sites/github/Magento-Lib/lib/" $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/lib/"
            cp -R "/Users/david/Sites/github/Magento-Lib/shell/" $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/shell/"
            cp -R "/Users/david/Sites/github/Magento-Extensions/MegaMenu/src/" $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/"
            cp -R "/Users/david/Sites/github/Magento-Extensions/UrlPorts/src/" $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/"
            echo "done"
        done
        for i in "${MAGENTO_SAFE_VERSIONS_ARRAY[@]}"
        do
            echo -n "    Updating database for $i..."
            $SQL_PATH -u$MYSQL_USER -p$MYSQL_PASS magento_$i < $SBP_PATH"/skywire_defaults/sql/001_config_reset.sql"
            $SQL_PATH -u$MYSQL_USER -p$MYSQL_PASS magento_$i < $SBP_PATH"/skywire_defaults/sql/002_optional_zip_countries.sql"
            # $SQL_PATH -u$MYSQL_USER -p$MYSQL_PASS magento_$i < $SBP_PATH"/skywire_defaults/sql/003_site_specific.sql" # this would need to be edited first
            $SQL_PATH -u$MYSQL_USER -p$MYSQL_PASS magento_$i < $SBP_PATH"/skywire_defaults/sql/004_symlinks.sql"
            echo "done"
        done
        for (( i = 0 ; i < ${#MAGENTO_VERSIONS_ARRAY[@]} ; i++ ))
        do
            echo "    Updating CMS pages/blocks for ${MAGENTO_VERSIONS_ARRAY[$i]}..."
            cd $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/skywire_defaults/php/"
            $PHP_PATH -f "cms_blocks.php"
            $PHP_PATH -f "cms_pages.php"
        done
        for (( i = 0 ; i < ${#MAGENTO_VERSIONS_ARRAY[@]} ; i++ ))
        do
            echo -n "    Patching index.php and app/etc/enterprise.xml for ${MAGENTO_VERSIONS_ARRAY[$i]}..."
            patch -s $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/index.php" < $SBP_PATH"/skywire_defaults/magento_developer_subdomains.patch"
            patch -s $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/app/etc/enterprise.xml" < $SBP_PATH"/skywire_defaults/enterprise_disable_auto_updates.patch"
            echo "done"
        done
    else
        echo "Skipping SMBP Installation"
    fi

    echo "Init Git? (y/n)"
    read INIT_GIT
    if [ $INIT_GIT == 'y' ]; then
        for (( i = 0 ; i < ${#MAGENTO_VERSIONS_ARRAY[@]} ; i++ ))
        do
            echo -n "    Setting up repo for ${MAGENTO_VERSIONS_ARRAY[$i]}..."
            rm -fr $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/.git"
            cd $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/"
            git init
            git add -A
            git commit -m "initial commit"
            echo "done"
        done
    else
        echo "Skipping Git Init"
    fi

    for (( i = 0 ; i < ${#MAGENTO_VERSIONS_ARRAY[@]} ; i++ ))
    do
        echo "    Reindexing ${MAGENTO_VERSIONS_ARRAY[$i]}..."
        cd $SITES_DIR"magento_${MAGENTO_VERSIONS_ARRAY[$i]}/"
        $PHP_PATH shell/indexer.php --reindexall
    done

    echo "Romeo...done."
}

if [ -n "$1" ] && [ "$1" == "delete" ]
    then
        echo "Are you sure you want to delete all your Magento installs? (enter 1 or 2)"
        select yn in "Yes" "No"; do
            case $yn in
                Yes ) remove_all_installs; break;;
                No ) echo "Chickening out eh?"; exit;;
            esac
        done
    else
        install_all_versions
fi