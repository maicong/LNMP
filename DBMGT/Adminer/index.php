<?php
function adminer_object() {
    // required to run any plugin
    include_once __DIR__ . "/plugins/plugin.php";

    // autoloader
    foreach (glob("plugins/*.php") as $filename) {
        include_once "./$filename";
    }

    $plugins = array(
        // specify enabled plugins here
        new AdminerDumpAlter,
        new AdminerDumpBz2,
        new AdminerDumpDate,
        new AdminerDumpJson,
        new AdminerDumpXml,
        new AdminerDumpZip,
        new AdminerEditTextarea,
        new AdminerEnumOption,
        new AdminerJsonColumn,
        new AdminerTranslation
    );

    /* It is possible to combine customization and plugins:
    class AdminerCustomization extends AdminerPlugin {
    }
    return new AdminerCustomization($plugins);
    */

    return new AdminerPlugin($plugins);
}

// include original Adminer or Adminer Editor
include __DIR__ . "/adminer.php";