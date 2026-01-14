#!/usr/bin/env python
"""
================================================================================
REPO2INTERACTIVE - GitHub Repository to Interactive Infographic JSON Generator
================================================================================

INPUT FILES:
    - GitHub repository URL (provided as command-line argument)
    
OUTPUT FILES:
    - repo2interactive_output/{repo-name}_interactive.json - Hierarchical JSON
      for iOS drill-down navigation with embedded code snippets

DESCRIPTION:
    This tool analyzes a GitHub repository using Gemini 3 Flash via OpenRouter
    to extract a hierarchical representation of the codebase suitable for
    interactive drill-down navigation on iOS devices.
    
    The output JSON contains:
    - Repository overview and pipeline summary
    - Phases (Ingestion, Processing, etc.)
    - Steps within each phase
    - Files involved in each step
    - Functions within each file
    - Actual code snippets at the leaf level
    
    Each level can be "zoomed into" by the iOS app via modal navigation.

VERSION HISTORY:
    v1.0 - Initial version for interactive infographic generation

LAST UPDATED: 2026-01-14
================================================================================
"""

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import requests
from dotenv import load_dotenv

from prompts_interactive import (
    build_hierarchical_analysis_prompt,
    get_phase_styling,
    get_language_color,
    PHASE_COLORS,
)


# ---------- Configuration ----------

DEFAULT_TEXT_MODEL = "google/gemini-3-flash-preview"
OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions"
DEFAULT_OUTPUT_DIR = "repo2interactive_output"


# ---------- API Functions ----------

def get_api_key() -> str:
    """
    Get OpenRouter API key from environment.
    
    Returns:
        API key string
        
    Raises:
        RuntimeError: If API key is not set
    """
    load_dotenv()
    api_key = os.getenv("OPENROUTER_API_KEY")
    if not api_key:
        raise RuntimeError(
            "OPENROUTER_API_KEY is not set. Put it in a .env file or export it in your shell."
        )
    return api_key


def call_text_model(api_key: str, model: str, prompt: str) -> dict:
    """
    Call the text model via OpenRouter to generate the hierarchical JSON.
    
    Args:
        api_key: OpenRouter API key
        model: Model identifier (e.g., "google/gemini-2.5-flash-preview-05-20")
        prompt: Complete prompt string
        
    Returns:
        Parsed JSON dictionary
        
    Raises:
        RuntimeError: If API call fails
        json.JSONDecodeError: If response is not valid JSON
    """
    print(f"[INFO] Calling text model: {model}")
    print("[INFO] Analyzing repository (this may take 1-2 minutes)...")

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://github.com/repo2interactive",
        "X-Title": "Repo2Interactive"
    }

    payload = {
        "model": model,
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ],
        "temperature": 0.2,  # Lower temperature for more consistent structure
        "max_tokens": 32000  # Larger limit for hierarchical output with code
    }

    response = requests.post(
        OPENROUTER_API_URL, 
        headers=headers, 
        json=payload, 
        timeout=300  # 5 minute timeout for large repos
    )
    
    if response.status_code != 200:
        print(f"[ERROR] API request failed: {response.status_code}", file=sys.stderr)
        print(f"Response: {response.text}", file=sys.stderr)
        raise RuntimeError(f"OpenRouter API error: {response.status_code}")

    result = response.json()
    
    if not result.get("choices") or not result["choices"][0].get("message"):
        print(f"[ERROR] Unexpected response format: {result}", file=sys.stderr)
        raise RuntimeError("No response from text model")

    raw = result["choices"][0]["message"]["content"].strip()
    
    # Strip markdown code blocks if present
    raw = extract_json_from_response(raw)
    
    try:
        parsed = json.loads(raw)
        print("[INFO] Successfully parsed hierarchical JSON")
        return parsed
    except json.JSONDecodeError as e:
        print("[ERROR] Failed to parse JSON from model response.", file=sys.stderr)
        print(f"Error: {e}", file=sys.stderr)
        print("Raw response (first 3000 chars):", file=sys.stderr)
        print(raw[:3000], file=sys.stderr)
        raise


def extract_json_from_response(raw: str) -> str:
    """
    Extract JSON from a response that may contain markdown or other text.
    
    Args:
        raw: Raw response string
        
    Returns:
        Cleaned JSON string
    """
    # Try to find JSON within markdown code blocks
    if "```" in raw:
        # Find the first { after a code block marker
        start_marker = raw.find("```")
        json_start = raw.find("{", start_marker)
        if json_start != -1:
            # Find the last } before the closing code block
            end_marker = raw.rfind("```")
            json_end = raw.rfind("}", 0, end_marker)
            if json_end != -1:
                return raw[json_start:json_end + 1]
    
    # Try to find raw JSON (first { to last })
    json_start = raw.find("{")
    json_end = raw.rfind("}")
    if json_start != -1 and json_end != -1:
        return raw[json_start:json_end + 1]
    
    # Return as-is if no JSON found
    return raw


# ---------- JSON Validation and Enhancement ----------

def validate_and_enhance_json(data: dict, repo_url: str) -> dict:
    """
    Validate the generated JSON and enhance it with additional metadata.
    
    Args:
        data: Parsed JSON dictionary
        repo_url: Original repository URL
        
    Returns:
        Enhanced JSON dictionary
    """
    # Ensure required top-level fields
    if "version" not in data:
        data["version"] = "2.0"
    if "schema" not in data:
        data["schema"] = "interactive-infographic"
    if "repo_url" not in data:
        data["repo_url"] = repo_url
    if "generated_at" not in data:
        data["generated_at"] = datetime.now(timezone.utc).isoformat()
    
    # Validate and enhance the tree structure
    if "root" in data:
        data["root"] = enhance_node(data["root"], repo_url)
    
    return data


def enhance_node(node: dict, repo_url: str, depth: int = 0) -> dict:
    """
    Recursively enhance a node with proper styling and validation.
    
    Args:
        node: Node dictionary
        repo_url: Repository URL for generating GitHub links
        depth: Current depth in the tree
        
    Returns:
        Enhanced node dictionary
    """
    # Ensure required fields
    if "id" not in node:
        node["id"] = f"node-{depth}-{id(node)}"
    if "type" not in node:
        node["type"] = infer_node_type(depth)
    if "label" not in node:
        node["label"] = "Unknown"
    if "children" not in node:
        node["children"] = []
    
    # Add visual hints if missing
    if "visual_hint" not in node:
        node["visual_hint"] = get_default_visual_hint(node["type"], node.get("label", ""))
    
    # Enhance GitHub URLs for code nodes
    if node["type"] == "code_block" and "code_metadata" in node:
        meta = node["code_metadata"]
        if "github_url" not in meta and "file_path" in meta:
            meta["github_url"] = generate_github_url(
                repo_url, 
                meta["file_path"],
                meta.get("line_start"),
                meta.get("line_end")
            )
    
    # Recursively enhance children
    node["children"] = [
        enhance_node(child, repo_url, depth + 1) 
        for child in node.get("children", [])
    ]
    
    return node


def infer_node_type(depth: int) -> str:
    """
    Infer node type based on depth in the tree.
    
    Args:
        depth: Depth in the tree (0 = root)
        
    Returns:
        Node type string
    """
    types = ["repo", "phase", "step", "file", "function", "code_block"]
    return types[min(depth, len(types) - 1)]


def get_default_visual_hint(node_type: str, label: str) -> dict:
    """
    Get default visual hints based on node type.
    
    Args:
        node_type: Type of the node
        label: Node label (used for phase coloring)
        
    Returns:
        Visual hint dictionary
    """
    defaults = {
        "repo": {"icon": "folder", "color": "#4A90D9"},
        "phase": {"icon": "rectangle.stack", "color": "#E8F4FD"},
        "step": {"icon": "arrow.right.circle", "color": "#4A90D9"},
        "file": {"icon": "doc.text", "color": "#6E7681"},
        "function": {"icon": "function", "color": "#3776AB"},
        "code_block": {"icon": "chevron.left.forwardslash.chevron.right", "color": "#3776AB"}
    }
    
    # Special handling for phases - use phase-specific colors
    if node_type == "phase":
        for phase_name, styling in PHASE_COLORS.items():
            if phase_name in label:
                return {
                    "icon": styling["icon"],
                    "color": styling["background"]
                }
    
    return defaults.get(node_type, {"icon": "questionmark.circle", "color": "#757575"})


def generate_github_url(repo_url: str, file_path: str, 
                        line_start: int = None, line_end: int = None) -> str:
    """
    Generate a GitHub URL for a file, optionally with line numbers.
    
    Args:
        repo_url: Base repository URL
        file_path: Path to file within the repository
        line_start: Optional starting line number
        line_end: Optional ending line number
        
    Returns:
        Full GitHub URL
    """
    # Clean the repo URL
    base = repo_url.rstrip("/")
    
    # Construct the file URL (assume main branch)
    url = f"{base}/blob/main/{file_path}"
    
    # Add line numbers if provided
    if line_start is not None:
        if line_end is not None and line_end != line_start:
            url += f"#L{line_start}-L{line_end}"
        else:
            url += f"#L{line_start}"
    
    return url


# ---------- Statistics ----------

def calculate_statistics(data: dict) -> dict:
    """
    Calculate statistics about the generated JSON.
    
    Args:
        data: Complete JSON dictionary
        
    Returns:
        Statistics dictionary
    """
    stats = {
        "total_nodes": 0,
        "phases": 0,
        "steps": 0,
        "files": 0,
        "functions": 0,
        "code_blocks": 0,
        "max_depth": 0,
        "total_code_lines": 0
    }
    
    def count_nodes(node: dict, depth: int = 0):
        stats["total_nodes"] += 1
        stats["max_depth"] = max(stats["max_depth"], depth)
        
        node_type = node.get("type", "")
        if node_type == "phase":
            stats["phases"] += 1
        elif node_type == "step":
            stats["steps"] += 1
        elif node_type == "file":
            stats["files"] += 1
        elif node_type == "function":
            stats["functions"] += 1
        elif node_type == "code_block":
            stats["code_blocks"] += 1
            # Count code lines
            if "code_metadata" in node and "code" in node["code_metadata"]:
                stats["total_code_lines"] += node["code_metadata"]["code"].count("\n") + 1
        
        for child in node.get("children", []):
            count_nodes(child, depth + 1)
    
    if "root" in data:
        count_nodes(data["root"])
    
    return stats


# ---------- CLI ----------

def main():
    """
    Main entry point for the repo2interactive CLI.
    """
    parser = argparse.ArgumentParser(
        description="Generate an interactive hierarchical JSON from a GitHub repo for iOS drill-down navigation."
    )
    parser.add_argument(
        "repo_url",
        help="GitHub repository URL (e.g., https://github.com/owner/repo)",
    )
    parser.add_argument(
        "--out-dir",
        default=DEFAULT_OUTPUT_DIR,
        help=f"Output directory for JSON (default: {DEFAULT_OUTPUT_DIR})",
    )
    parser.add_argument(
        "--text-model",
        default=DEFAULT_TEXT_MODEL,
        help=f"Text model to use (default: {DEFAULT_TEXT_MODEL})",
    )
    parser.add_argument(
        "--validate-only",
        action="store_true",
        help="Only validate an existing JSON file (provide path as repo_url)",
    )
    args = parser.parse_args()

    # Extract repo name from URL for output filename
    repo_name = args.repo_url.rstrip('/').split('/')[-1]
    if not repo_name:
        repo_name = "interactive"

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    output_path = out_dir / f"{repo_name}_interactive.json"

    # Validation-only mode
    if args.validate_only:
        print(f"[INFO] Validating existing JSON: {args.repo_url}")
        with open(args.repo_url, "r", encoding="utf-8") as f:
            data = json.load(f)
        stats = calculate_statistics(data)
        print_statistics(stats)
        print("[DONE] Validation complete.")
        return

    # Normal mode: analyze repository
    api_key = get_api_key()

    # Step 1: Generate hierarchical JSON via text model
    prompt = build_hierarchical_analysis_prompt(args.repo_url)
    raw_json = call_text_model(
        api_key=api_key,
        model=args.text_model,
        prompt=prompt,
    )

    # Step 2: Validate and enhance the JSON
    print("[INFO] Validating and enhancing JSON structure...")
    enhanced_json = validate_and_enhance_json(raw_json, args.repo_url)

    # Step 3: Calculate and display statistics
    stats = calculate_statistics(enhanced_json)
    print_statistics(stats)

    # Step 4: Save the output
    with output_path.open("w", encoding="utf-8") as f:
        json.dump(enhanced_json, f, indent=2, ensure_ascii=False)
    print(f"[INFO] Saved interactive JSON to: {output_path}")

    print("[DONE] Interactive infographic JSON generation complete.")


def print_statistics(stats: dict):
    """
    Print statistics about the generated JSON.
    
    Args:
        stats: Statistics dictionary
    """
    print("\n" + "=" * 50)
    print("GENERATION STATISTICS")
    print("=" * 50)
    print(f"  Total nodes:     {stats['total_nodes']}")
    print(f"  Phases:          {stats['phases']}")
    print(f"  Steps:           {stats['steps']}")
    print(f"  Files:           {stats['files']}")
    print(f"  Functions:       {stats['functions']}")
    print(f"  Code blocks:     {stats['code_blocks']}")
    print(f"  Max depth:       {stats['max_depth']}")
    print(f"  Total code lines:{stats['total_code_lines']}")
    print("=" * 50 + "\n")


if __name__ == "__main__":
    main()
