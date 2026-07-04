import os
import re
import base64
import subprocess
import configparser

def get_credentials():
    # 1. Try to read ~/.aws/credentials
    credentials_path = os.path.expanduser("~/.aws/credentials")
    if os.path.exists(credentials_path):
        try:
            config = configparser.ConfigParser()
            config.read(credentials_path)
            profile = "default"
            if config.has_section(profile):
                ak = config.get(profile, "aws_access_key_id", fallback=None)
                sk = config.get(profile, "aws_secret_access_key", fallback=None)
                st = config.get(profile, "aws_session_token", fallback=None)
                if ak and sk:
                    return ak, sk, st
        except Exception as e:
            print(f"Warning: Failed to read AWS credentials file: {e}")

    # 2. Try environment variables
    ak = os.getenv("AWS_ACCESS_KEY_ID")
    sk = os.getenv("AWS_SECRET_ACCESS_KEY")
    st = os.getenv("AWS_SESSION_TOKEN")
    if ak and sk:
        return ak, sk, st

    return None, None, None

def main():
    print("Fetching active AWS credentials...")
    ak, sk, st = get_credentials()
    
    if not ak or not sk:
        print("Error: Could not locate active AWS credentials in ~/.aws/credentials or environment variables.")
        print("Please run 'aws configure' or update your credentials file first.")
        return

    print("AWS credentials detected successfully.")
    
    # Encode to base64
    ak_b64 = base64.b64encode(ak.encode('utf-8')).decode('utf-8')
    sk_b64 = base64.b64encode(sk.encode('utf-8')).decode('utf-8')
    st_b64 = base64.b64encode(st.encode('utf-8')).decode('utf-8') if st else ""

    # Patch local files
    k8s_dir = "k8s"
    files_to_patch = ["analytics-service.yaml", "evaluation-service.yaml"]
    
    for filename in files_to_patch:
        filepath = os.path.join(k8s_dir, filename)
        if not os.path.exists(filepath):
            continue
            
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        secret_name = filename.replace(".yaml", "-secret")
        pattern = rf"(name:\s*{secret_name}\s*\n\s*namespace:\s*toogle-master\s*\n\s*type:\s*Opaque\s*\n\s*data:\s*\n)(.*?)(\n---|\Z)"
        
        def replacer(match):
            prefix = match.group(1)
            data_block = match.group(2)
            suffix = match.group(3)
            
            lines = data_block.split('\n')
            new_lines = []
            for line in lines:
                if not line.strip():
                    continue
                key_match = re.match(r"^\s*([a-zA-Z0-9_]+)\s*:", line)
                if key_match:
                    key = key_match.group(1)
                    if key in ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN"]:
                        continue
                new_lines.append(line)
                
            new_lines.append(f"  AWS_ACCESS_KEY_ID: {ak_b64}")
            new_lines.append(f"  AWS_SECRET_ACCESS_KEY: {sk_b64}")
            if st_b64:
                new_lines.append(f"  AWS_SESSION_TOKEN: {st_b64}")
            
            return prefix + "\n".join(new_lines) + suffix

        new_content = re.sub(pattern, replacer, content, flags=re.DOTALL)
        
        with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
            f.write(new_content)
        print(f"Patched local file: {filepath}")

    # Now deploy to Kubernetes
    print("Applying updated manifests to the Kubernetes cluster...")
    try:
        subprocess.run(["kubectl", "apply", "-f", "k8s/"], check=True)
        print("Manifests applied successfully.")
    except Exception as e:
        print(f"Error executing kubectl apply: {e}")
        return

    # Restart deployments to reload credentials
    print("Restarting deployments to apply new credentials...")
    try:
        subprocess.run([
            "kubectl", "rollout", "restart", "deployment", 
            "analytics-service", "evaluation-service", "-n", "toogle-master"
        ], check=True)
        print("Deployments restarted successfully!")
    except Exception as e:
        print(f"Error executing kubectl rollout restart: {e}")

if __name__ == "__main__":
    main()
