#!/usr/bin/env python3
"""
Generate a valid Xcode project for Spoken Reality
"""

import os
import uuid
import subprocess

def generate_uuid():
    return str(uuid.uuid4()).replace('-', '')[:24].upper()

def create_xcode_project():
    project_name = "SpokenRealityApp"
    bundle_id = "com.spokenreality.app"

    # Source files
    source_files = [
        "SpokenReality-iOS/SpokenReality/Core/Theme/Colors.swift",
        "SpokenReality-iOS/SpokenReality/Core/Theme/Typography.swift",
        "SpokenReality-iOS/SpokenReality/Core/Theme/Spacing.swift",
        "SpokenReality-iOS/SpokenReality/Core/Components/FloatingButton.swift",
        "SpokenReality-iOS/SpokenReality/Core/Components/ProgressBar.swift",
        "SpokenReality-iOS/SpokenReality/Features/Development/WebView.swift",
        "SpokenReality-iOS/SpokenReality/Features/Development/DevelopmentView.swift",
        "SpokenReality-iOS/SpokenReality/Features/Home/HomeView.swift",
        "SpokenReality-iOS/SpokenReality/Features/Home/ProjectCard.swift",
        "SpokenReality-iOS/SpokenReality/Models/Project.swift",
        "SpokenReality-iOS/SpokenReality/App/SpokenRealityApp.swift",
    ]

    # Create project directory structure
    proj_dir = f"{project_name}.xcodeproj"
    os.makedirs(proj_dir, exist_ok=True)
    os.makedirs(f"{proj_dir}/project.xcworkspace", exist_ok=True)
    os.makedirs(f"{proj_dir}/project.xcworkspace/xcshareddata", exist_ok=True)

    # Generate UUIDs for project elements
    project_uuid = generate_uuid()
    target_uuid = generate_uuid()
    sources_phase_uuid = generate_uuid()
    frameworks_phase_uuid = generate_uuid()
    resources_phase_uuid = generate_uuid()

    # Generate file reference UUIDs
    file_uuids = {f: generate_uuid() for f in source_files}
    build_file_uuids = {f: generate_uuid() for f in source_files}

    # Create project.pbxproj content
    pbxproj_content = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
"""

    # Add build files
    for file_path in source_files:
        filename = os.path.basename(file_path)
        pbxproj_content += f"\t\t{build_file_uuids[file_path]} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuids[file_path]} /* {filename} */; }};\n"

    pbxproj_content += """/* End PBXBuildFile section */

/* Begin PBXFileReference section */
"""

    # Add file references
    for file_path in source_files:
        filename = os.path.basename(file_path)
        pbxproj_content += f"\t\t{file_uuids[file_path]} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{filename}\"; sourceTree = \"<group>\"; }};\n"

    pbxproj_content += f"""/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworks_phase_uuid} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{generate_uuid()} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
"""

    # Add all files to group
    for file_path in source_files:
        filename = os.path.basename(file_path)
        pbxproj_content += f"\t\t\t\t{file_uuids[file_path]} /* {filename} */,\n"

    pbxproj_content += f"""\t\t\t);
\t\t\tpath = {project_name};
\t\t\tsourceTree = \"<group>\";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{target_uuid} /* {project_name} */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {generate_uuid()};
\t\t\tbuildPhases = (
\t\t\t\t{sources_phase_uuid} /* Sources */,
\t\t\t\t{frameworks_phase_uuid} /* Frameworks */,
\t\t\t\t{resources_phase_uuid} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = {project_name};
\t\t\tproductName = {project_name};
\t\t\tproductType = \"com.apple.product-type.application\";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{project_uuid} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1600;
\t\t\t\tLastUpgradeCheck = 1600;
\t\t\t}};
\t\t\tbuildConfigurationList = {generate_uuid()};
\t\t\tcompatibilityVersion = \"Xcode 14.0\";
\t\t\thasScannedForEncodings = 0;
\t\t\tmainGroup = {generate_uuid()};
\t\t\tproductRefGroup = {generate_uuid()};
\t\t\tprojectDirPath = \"\";
\t\t\tprojectRoot = \"\";
\t\t\ttargets = (
\t\t\t\t{target_uuid} /* {project_name} */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resources_phase_uuid} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{sources_phase_uuid} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
"""

    # Add all build files to sources phase
    for file_path in source_files:
        filename = os.path.basename(file_path)
        pbxproj_content += f"\t\t\t\t{build_file_uuids[file_path]} /* {filename} in Sources */,\n"

    pbxproj_content += f"""\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

\t}};
\trootObject = {project_uuid} /* Project object */;
}}
"""

    # Write project.pbxproj
    with open(f"{proj_dir}/project.pbxproj", "w") as f:
        f.write(pbxproj_content)

    # Create workspace data
    workspace_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:{project_name}.xcodeproj">
   </FileRef>
</Workspace>
"""

    with open(f"{proj_dir}/project.xcworkspace/contents.xcworkspacedata", "w") as f:
        f.write(workspace_content)

    print(f"✓ Created {proj_dir}")
    print(f"✓ Added {len(source_files)} Swift files")
    print(f"\nNow opening in Xcode...")

    # Open in Xcode
    subprocess.run(["open", f"{proj_dir}"])

if __name__ == "__main__":
    os.chdir("/Users/arjundivecha/Dropbox/AAA Backup/A Working/Spoken Reality")
    create_xcode_project()
