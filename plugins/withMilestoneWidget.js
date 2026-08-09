/**
 * Expo Config Plugin: withMilestoneWidget
 *
 * Adds an iOS WidgetKit extension target to the Xcode project during prebuild.
 * - Creates the MilestoneWidget target with proper build settings
 * - Adds App Groups entitlement to both app and widget
 * - Copies Swift widget source files into the extension
 * - Configures Info.plist for the widget extension
 */
const {
  withXcodeProject,
  withEntitlementsPlist,
  withInfoPlist,
  IOSConfig,
} = require('expo/config-plugins');
const fs = require('fs');
const path = require('path');

const WIDGET_TARGET_NAME = 'MilestoneWidget';
const WIDGET_BUNDLE_SUFFIX = '.widget';
const APP_GROUP_ID = 'group.com.mathurharsh.milestone';

/**
 * Step 1: Add App Groups entitlement to the main app target
 */
function withAppGroupEntitlement(config) {
  return withEntitlementsPlist(config, (mod) => {
    mod.modResults['com.apple.security.application-groups'] = [APP_GROUP_ID];
    return mod;
  });
}

/**
 * Step 2: Add the widget extension target to the Xcode project
 */
function withWidgetTarget(config) {
  return withXcodeProject(config, async (mod) => {
    const xcodeProject = mod.modResults;
    const projectRoot = mod.modRequest.projectRoot;
    const platformProjectRoot = mod.modRequest.platformProjectRoot; // ios/
    const appBundleId = mod.modRequest.projectName
      ? `com.mathurharsh.milestone`
      : config.ios?.bundleIdentifier || 'com.mathurharsh.milestone';
    const widgetBundleId = `${appBundleId}${WIDGET_BUNDLE_SUFFIX}`;

    // ── Copy widget Swift sources into ios/MilestoneWidget/ ──
    const widgetSrcDir = path.join(projectRoot, 'ios-widget');
    const widgetDestDir = path.join(platformProjectRoot, WIDGET_TARGET_NAME);

    if (!fs.existsSync(widgetDestDir)) {
      fs.mkdirSync(widgetDestDir, { recursive: true });
    }

    const swiftFiles = fs.readdirSync(widgetSrcDir).filter((f) => f.endsWith('.swift'));
    for (const file of swiftFiles) {
      fs.copyFileSync(path.join(widgetSrcDir, file), path.join(widgetDestDir, file));
    }

    // ── Create widget entitlements file ──
    const widgetEntitlements = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.application-groups</key>
  <array>
    <string>${APP_GROUP_ID}</string>
  </array>
</dict>
</plist>`;
    const entitlementsPath = path.join(widgetDestDir, `${WIDGET_TARGET_NAME}.entitlements`);
    fs.writeFileSync(entitlementsPath, widgetEntitlements);

    // ── Create widget Info.plist ──
    const widgetInfoPlist = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>Milestone</string>
  <key>CFBundleExecutable</key>
  <string>$(EXECUTABLE_NAME)</string>
  <key>CFBundleIdentifier</key>
  <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$(PRODUCT_NAME)</string>
  <key>CFBundlePackageType</key>
  <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
  <key>CFBundleShortVersionString</key>
  <string>$(MARKETING_VERSION)</string>
  <key>CFBundleVersion</key>
  <string>$(CURRENT_PROJECT_VERSION)</string>
  <key>NSExtension</key>
  <dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
  </dict>
</dict>
</plist>`;
    fs.writeFileSync(path.join(widgetDestDir, 'Info.plist'), widgetInfoPlist);

    // ── Add widget target to Xcode project ──
    const targetUuid = xcodeProject.generateUuid();
    const productFileUuid = xcodeProject.generateUuid();
    const buildConfigListUuid = xcodeProject.generateUuid();
    const debugBuildConfigUuid = xcodeProject.generateUuid();
    const releaseBuildConfigUuid = xcodeProject.generateUuid();
    const sourcesBuildPhaseUuid = xcodeProject.generateUuid();
    const frameworksBuildPhaseUuid = xcodeProject.generateUuid();
    const resourcesBuildPhaseUuid = xcodeProject.generateUuid();

    // Add widget PBXGroup
    const widgetGroupKey = xcodeProject.pbxCreateGroup(WIDGET_TARGET_NAME, `"${WIDGET_TARGET_NAME}"`);

    // Add Swift source files to the project
    const sourceFileRefs = [];
    const buildFileRefs = [];
    for (const file of swiftFiles) {
      const fileRefUuid = xcodeProject.generateUuid();
      const buildFileUuid = xcodeProject.generateUuid();

      xcodeProject.addToPbxFileReferenceSection({
        fileRef: fileRefUuid,
        isa: 'PBXFileReference',
        lastKnownFileType: 'sourcecode.swift',
        path: file,
        sourceTree: '"<group>"',
        basename: file,
      });

      xcodeProject.addToPbxBuildFileSection({
        uuid: buildFileUuid,
        isa: 'PBXBuildFile',
        fileRef: fileRefUuid,
        basename: file,
        group: 'Sources',
      });

      sourceFileRefs.push({ uuid: fileRefUuid, name: file });
      buildFileRefs.push({ uuid: buildFileUuid, name: file });

      // Add to widget group
      xcodeProject.addToPbxGroup(
        { fileRef: fileRefUuid, basename: file },
        widgetGroupKey
      );
    }

    // Add entitlements file reference
    const entitlementsRefUuid = xcodeProject.generateUuid();
    xcodeProject.addToPbxFileReferenceSection({
      fileRef: entitlementsRefUuid,
      isa: 'PBXFileReference',
      lastKnownFileType: 'text.plist.entitlements',
      path: `${WIDGET_TARGET_NAME}.entitlements`,
      sourceTree: '"<group>"',
      basename: `${WIDGET_TARGET_NAME}.entitlements`,
    });
    xcodeProject.addToPbxGroup(
      { fileRef: entitlementsRefUuid, basename: `${WIDGET_TARGET_NAME}.entitlements` },
      widgetGroupKey
    );

    // Add Info.plist file reference
    const infoPlistRefUuid = xcodeProject.generateUuid();
    xcodeProject.addToPbxFileReferenceSection({
      fileRef: infoPlistRefUuid,
      isa: 'PBXFileReference',
      lastKnownFileType: 'text.plist.xml',
      path: 'Info.plist',
      sourceTree: '"<group>"',
      basename: 'Info.plist',
    });
    xcodeProject.addToPbxGroup(
      { fileRef: infoPlistRefUuid, basename: 'Info.plist' },
      widgetGroupKey
    );

    // Add widget group to main project group
    const mainGroupKey = xcodeProject.getFirstProject().firstProject.mainGroup;
    xcodeProject.addToPbxGroup(
      widgetGroupKey,
      mainGroupKey
    );

    // ── Build configurations for widget target ──
    const commonBuildSettings = {
      ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: 'AccentColor',
      ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME: 'WidgetBackground',
      CODE_SIGN_ENTITLEMENTS: `${WIDGET_TARGET_NAME}/${WIDGET_TARGET_NAME}.entitlements`,
      CODE_SIGN_STYLE: 'Automatic',
      DEVELOPMENT_TEAM: config.ios?.appleTeamId || '""',
      CURRENT_PROJECT_VERSION: '1',
      GENERATE_INFOPLIST_FILE: 'YES',
      INFOPLIST_FILE: `${WIDGET_TARGET_NAME}/Info.plist`,
      INFOPLIST_KEY_CFBundleDisplayName: 'Milestone',
      INFOPLIST_KEY_NSHumanReadableCopyright: '""',
      IPHONEOS_DEPLOYMENT_TARGET: '17.0',
      LD_RUNPATH_SEARCH_PATHS: '"$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks"',
      MARKETING_VERSION: '1.0.0',
      PRODUCT_BUNDLE_IDENTIFIER: `"${widgetBundleId}"`,
      PRODUCT_NAME: `"$(TARGET_NAME)"`,
      SKIP_INSTALL: 'YES',
      SWIFT_EMIT_LOC_STRINGS: 'YES',
      SWIFT_VERSION: '5.0',
      TARGETED_DEVICE_FAMILY: '"1"',
    };

    // Create build configurations
    const pbxBuildConfigSection = xcodeProject.pbxXCBuildConfigurationSection();

    pbxBuildConfigSection[debugBuildConfigUuid] = {
      isa: 'XCBuildConfiguration',
      buildSettings: { ...commonBuildSettings, CODE_SIGN_IDENTITY: '"Apple Development"', DEBUG_INFORMATION_FORMAT: '"dwarf-with-dsym"', MTL_ENABLE_DEBUG_INFO: 'INCLUDE_SOURCE', SWIFT_OPTIMIZATION_LEVEL: '"-Onone"' },
      name: 'Debug',
    };
    pbxBuildConfigSection[`${debugBuildConfigUuid}_comment`] = 'Debug';

    pbxBuildConfigSection[releaseBuildConfigUuid] = {
      isa: 'XCBuildConfiguration',
      buildSettings: { ...commonBuildSettings, CODE_SIGN_IDENTITY: '"Apple Distribution"', SWIFT_OPTIMIZATION_LEVEL: '"-O"', COPY_PHASE_STRIP: 'NO' },
      name: 'Release',
    };
    pbxBuildConfigSection[`${releaseBuildConfigUuid}_comment`] = 'Release';

    // Create XCConfigurationList
    const configListSection = xcodeProject.pbxXCConfigurationList();
    configListSection[buildConfigListUuid] = {
      isa: 'XCConfigurationList',
      buildConfigurations: [
        { value: debugBuildConfigUuid, comment: 'Debug' },
        { value: releaseBuildConfigUuid, comment: 'Release' },
      ],
      defaultConfigurationIsVisible: 0,
      defaultConfigurationName: 'Release',
    };
    configListSection[`${buildConfigListUuid}_comment`] = `Build configuration list for PBXNativeTarget "${WIDGET_TARGET_NAME}"`;

    // ── Build phases ──
    const buildPhaseSection = xcodeProject.hash.project.objects['PBXSourcesBuildPhase'] || {};
    xcodeProject.hash.project.objects['PBXSourcesBuildPhase'] = buildPhaseSection;

    buildPhaseSection[sourcesBuildPhaseUuid] = {
      isa: 'PBXSourcesBuildPhase',
      buildActionMask: 2147483647,
      files: buildFileRefs.map((f) => ({ value: f.uuid, comment: `${f.name} in Sources` })),
      runOnlyForDeploymentPostprocessing: 0,
    };
    buildPhaseSection[`${sourcesBuildPhaseUuid}_comment`] = 'Sources';

    const frameworksSection = xcodeProject.hash.project.objects['PBXFrameworksBuildPhase'] || {};
    xcodeProject.hash.project.objects['PBXFrameworksBuildPhase'] = frameworksSection;

    frameworksSection[frameworksBuildPhaseUuid] = {
      isa: 'PBXFrameworksBuildPhase',
      buildActionMask: 2147483647,
      files: [],
      runOnlyForDeploymentPostprocessing: 0,
    };
    frameworksSection[`${frameworksBuildPhaseUuid}_comment`] = 'Frameworks';

    const resourcesSection = xcodeProject.hash.project.objects['PBXResourcesBuildPhase'] || {};
    xcodeProject.hash.project.objects['PBXResourcesBuildPhase'] = resourcesSection;

    resourcesBuildPhaseUuid && (resourcesSection[resourcesBuildPhaseUuid] = {
      isa: 'PBXResourcesBuildPhase',
      buildActionMask: 2147483647,
      files: [],
      runOnlyForDeploymentPostprocessing: 0,
    });
    resourcesSection[`${resourcesBuildPhaseUuid}_comment`] = 'Resources';

    // ── Product reference ──
    const productRefSection = xcodeProject.hash.project.objects['PBXFileReference'];
    productRefSection[productFileUuid] = {
      isa: 'PBXFileReference',
      explicitFileType: '"wrapper.app-extension"',
      includeInIndex: 0,
      path: `"${WIDGET_TARGET_NAME}.appex"`,
      sourceTree: 'BUILT_PRODUCTS_DIR',
    };
    productRefSection[`${productFileUuid}_comment`] = `${WIDGET_TARGET_NAME}.appex`;

    // Add to Products group
    const productsGroupKey = xcodeProject.pbxGroupByName('Products')
      ? Object.keys(xcodeProject.hash.project.objects['PBXGroup']).find(
          (key) =>
            !key.endsWith('_comment') &&
            xcodeProject.hash.project.objects['PBXGroup'][key].name === 'Products'
        )
      : null;

    if (productsGroupKey) {
      xcodeProject.addToPbxGroup(
        { fileRef: productFileUuid, basename: `${WIDGET_TARGET_NAME}.appex` },
        productsGroupKey
      );
    }

    // ── Create PBXNativeTarget ──
    const nativeTargetSection = xcodeProject.hash.project.objects['PBXNativeTarget'];
    nativeTargetSection[targetUuid] = {
      isa: 'PBXNativeTarget',
      buildConfigurationList: buildConfigListUuid,
      buildConfigurationList_comment: `Build configuration list for PBXNativeTarget "${WIDGET_TARGET_NAME}"`,
      buildPhases: [
        { value: sourcesBuildPhaseUuid, comment: 'Sources' },
        { value: frameworksBuildPhaseUuid, comment: 'Frameworks' },
        { value: resourcesBuildPhaseUuid, comment: 'Resources' },
      ],
      buildRules: [],
      dependencies: [],
      name: `"${WIDGET_TARGET_NAME}"`,
      productName: `"${WIDGET_TARGET_NAME}"`,
      productReference: productFileUuid,
      productReference_comment: `${WIDGET_TARGET_NAME}.appex`,
      productType: '"com.apple.product-type.app-extension"',
    };
    nativeTargetSection[`${targetUuid}_comment`] = WIDGET_TARGET_NAME;

    // Add target to project
    const projectObj = xcodeProject.getFirstProject().firstProject;
    projectObj.targets.push({ value: targetUuid, comment: WIDGET_TARGET_NAME });

    // ── Add widget as dependency of main app (embed extension) ──
    const containerItemProxyUuid = xcodeProject.generateUuid();
    const targetDependencyUuid = xcodeProject.generateUuid();
    const copyFilesBuildPhaseUuid = xcodeProject.generateUuid();
    const embedBuildFileUuid = xcodeProject.generateUuid();

    // PBXContainerItemProxy
    const containerSection = xcodeProject.hash.project.objects['PBXContainerItemProxy'] || {};
    xcodeProject.hash.project.objects['PBXContainerItemProxy'] = containerSection;
    containerSection[containerItemProxyUuid] = {
      isa: 'PBXContainerItemProxy',
      containerPortal: projectObj.uuid || xcodeProject.getFirstProject().uuid,
      containerPortal_comment: 'Project object',
      proxyType: 1,
      remoteGlobalIDString: targetUuid,
      remoteInfo: `"${WIDGET_TARGET_NAME}"`,
    };
    containerSection[`${containerItemProxyUuid}_comment`] = 'PBXContainerItemProxy';

    // PBXTargetDependency
    const depSection = xcodeProject.hash.project.objects['PBXTargetDependency'] || {};
    xcodeProject.hash.project.objects['PBXTargetDependency'] = depSection;
    depSection[targetDependencyUuid] = {
      isa: 'PBXTargetDependency',
      target: targetUuid,
      target_comment: WIDGET_TARGET_NAME,
      targetProxy: containerItemProxyUuid,
      targetProxy_comment: 'PBXContainerItemProxy',
    };
    depSection[`${targetDependencyUuid}_comment`] = 'PBXTargetDependency';

    // Add dependency to main app target
    const mainTargetKey = Object.keys(nativeTargetSection).find(
      (key) =>
        !key.endsWith('_comment') &&
        nativeTargetSection[key].isa === 'PBXNativeTarget' &&
        nativeTargetSection[key].productType === '"com.apple.product-type.application"'
    );
    if (mainTargetKey) {
      if (!nativeTargetSection[mainTargetKey].dependencies) {
        nativeTargetSection[mainTargetKey].dependencies = [];
      }
      nativeTargetSection[mainTargetKey].dependencies.push({
        value: targetDependencyUuid,
        comment: 'PBXTargetDependency',
      });
    }

    // Embed App Extensions (Copy Files Build Phase)
    xcodeProject.addToPbxBuildFileSection({
      uuid: embedBuildFileUuid,
      isa: 'PBXBuildFile',
      fileRef: productFileUuid,
      basename: `${WIDGET_TARGET_NAME}.appex`,
      group: 'Embed Foundation Extensions',
      settings: { ATTRIBUTES: ['RemoveHeadersOnCopy'] },
    });

    const copyFilesSection = xcodeProject.hash.project.objects['PBXCopyFilesBuildPhase'] || {};
    xcodeProject.hash.project.objects['PBXCopyFilesBuildPhase'] = copyFilesSection;
    copyFilesSection[copyFilesBuildPhaseUuid] = {
      isa: 'PBXCopyFilesBuildPhase',
      buildActionMask: 2147483647,
      dstPath: '""',
      dstSubfolderSpec: 13, // Plugins folder (app extensions)
      files: [{ value: embedBuildFileUuid, comment: `${WIDGET_TARGET_NAME}.appex in Embed Foundation Extensions` }],
      name: '"Embed Foundation Extensions"',
      runOnlyForDeploymentPostprocessing: 0,
    };
    copyFilesSection[`${copyFilesBuildPhaseUuid}_comment`] = 'Embed Foundation Extensions';

    // Add embed phase to main target
    if (mainTargetKey) {
      nativeTargetSection[mainTargetKey].buildPhases.push({
        value: copyFilesBuildPhaseUuid,
        comment: 'Embed Foundation Extensions',
      });
    }

    return mod;
  });
}

/**
 * Main plugin entry point
 */
function withMilestoneWidget(config) {
  config = withAppGroupEntitlement(config);
  config = withWidgetTarget(config);
  return config;
}

module.exports = withMilestoneWidget;
