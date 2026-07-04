import os
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
    
    # Write directly to k8s/.env.aws
    env_content = f"AWS_ACCESS_KEY_ID={ak}\nAWS_SECRET_ACCESS_KEY={sk}\n"
    if st:
        env_content += f"AWS_SESSION_TOKEN={st}\n"

    env_path = os.path.join("k8s", ".env.aws")
    with open(env_path, "w", encoding="utf-8") as f:
        f.write(env_content)
    print(f"Updated: {env_path}")

    # Clean up old k8s/.env if it exists (no longer used)
    old_env_path = os.path.join("k8s", ".env")
    if os.path.exists(old_env_path):
        try:
            os.remove(old_env_path)
        except Exception:
            pass

    # Deploy using Kustomize
    print("Deploying manifests to EKS via Kustomize...")
    try:
        subprocess.run(["kubectl", "apply", "-k", "k8s/"], check=True)
        print("\nDeployment completed successfully!")
        print("Kustomize automatically regenerated the secrets and EKS will execute a rolling update on the pods.")
    except Exception as e:
        print(f"Error executing kubectl apply: {e}")

if __name__ == "__main__":
    main()
