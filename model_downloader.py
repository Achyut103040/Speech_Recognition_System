import os
import shutil
import requests
import tarfile
import zipfile
from math import floor


def download_and_extract(url, dest_dir, progress_callback=None):
    """Download an archive from `url` and extract to `dest_dir`.

    Supports .zip and .tar.gz/.tgz archives. Returns path to extracted folder.
    """
    os.makedirs(dest_dir, exist_ok=True)
    fname = url.split('/')[-1]
    download_path = os.path.join(dest_dir, fname)

    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        total = r.headers.get('Content-Length')
        if total is not None:
            total = int(total)
        downloaded = 0
        with open(download_path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    if progress_callback and total:
                        percent = floor(downloaded * 100 / total)
                        try:
                            progress_callback(percent)
                        except Exception:
                            pass

    # extract
    if download_path.endswith('.zip'):
        with zipfile.ZipFile(download_path, 'r') as z:
            z.extractall(dest_dir)
    elif download_path.endswith(('.tar.gz', '.tgz', '.tar')):
        with tarfile.open(download_path, 'r:*') as t:
            t.extractall(dest_dir)
    else:
        # assume model is a directory or file — move into place
        target = os.path.join(dest_dir, fname)
        shutil.move(download_path, target)

    # attempt to find top-level folder
    entries = [os.path.join(dest_dir, e) for e in os.listdir(dest_dir)]
    entries = [e for e in entries if os.path.isdir(e)]
    if entries:
        # return first directory
        return entries[0]
    return dest_dir


def ensure_vosk_model(local_models_dir='models', model_url=None, progress_callback=None):
    """Ensure there's at least one model under `local_models_dir`.

    If `model_url` is provided, download and extract.
    Returns the path to the model directory (or None if missing).
    """
    os.makedirs(local_models_dir, exist_ok=True)
    # look for existing subdirs
    for name in os.listdir(local_models_dir):
        p = os.path.join(local_models_dir, name)
        if os.path.isdir(p):
            # basic heuristic: presence of 'conf' or 'README' (vosk models often have 'am' etc.)
            return p

    if model_url:
        return download_and_extract(model_url, local_models_dir, progress_callback=progress_callback)

    return None
