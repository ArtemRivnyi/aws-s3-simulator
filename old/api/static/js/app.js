const API_BASE = '/api/v1/s3';
let currentBucket = null;

// --- Initialization ---
document.addEventListener('DOMContentLoaded', () => {
    loadBuckets();
});

// --- Bucket Operations ---
async function loadBuckets() {
    const bucketList = document.getElementById('bucket-list');
    bucketList.innerHTML = '<div class="animate-pulse space-y-2"><div class="h-8 bg-gray-200 rounded"></div></div>';

    try {
        const response = await fetch(`${API_BASE}/buckets`);
        const buckets = await response.json();

        bucketList.innerHTML = '';
        if (buckets.length === 0) {
            bucketList.innerHTML = '<div class="text-center text-gray-500 p-4">No buckets found</div>';
            return;
        }

        buckets.forEach(bucket => {
            const div = document.createElement('div');
            div.className = `p-3 rounded cursor-pointer hover:bg-blue-50 transition flex justify-between items-center group ${currentBucket === bucket.Name ? 'bg-blue-100 text-blue-700 font-medium' : 'text-gray-700'}`;
            div.onclick = () => selectBucket(bucket.Name);
            div.innerHTML = `
                <span class="truncate flex-1">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 inline mr-2 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                    </svg>
                    ${bucket.Name}
                </span>
                <button onclick="deleteBucket(event, '${bucket.Name}')" class="text-red-400 hover:text-red-600 opacity-0 group-hover:opacity-100 transition p-1">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                    </svg>
                </button>
            `;
            bucketList.appendChild(div);
        });
    } catch (error) {
        showToast('Failed to load buckets', 'error');
        console.error(error);
    }
}

function selectBucket(bucketName) {
    currentBucket = bucketName;
    document.getElementById('current-bucket-name').textContent = bucketName;
    loadBuckets(); // Re-render to update active state
    loadObjects(bucketName);
}

async function createBucket() {
    const nameInput = document.getElementById('new-bucket-name');
    const name = nameInput.value.trim();
    if (!name) return;

    // S3 Bucket Naming Rules Validation
    const s3NamingRules = /^[a-z0-9.-]{3,63}$/;
    if (!s3NamingRules.test(name) || name.includes('..') || name.startsWith('.') || name.startsWith('-') || name.endsWith('.') || name.endsWith('-')) {
        showToast('Invalid bucket name. Use only lowercase letters, numbers, dots, and hyphens. Length 3-63.', 'error');
        return;
    }

    try {
        const response = await fetch(`${API_BASE}/buckets`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name })
        });

        if (response.ok) {
            showToast(`Bucket ${name} created`);
            closeCreateBucketModal();
            nameInput.value = '';
            loadBuckets();
        } else {
            const data = await response.json();
            showToast(data.error || 'Failed to create bucket', 'error');
        }
    } catch (error) {
        showToast('Error creating bucket', 'error');
    }
}

async function deleteBucket(event, bucketName) {
    event.stopPropagation();
    if (!confirm(`Are you sure you want to delete bucket "${bucketName}"?`)) return;

    try {
        const response = await fetch(`${API_BASE}/buckets/${bucketName}`, {
            method: 'DELETE'
        });

        if (response.ok) {
            showToast(`Bucket ${bucketName} deleted`);
            if (currentBucket === bucketName) {
                currentBucket = null;
                document.getElementById('current-bucket-name').textContent = 'Select a bucket';
                document.getElementById('object-list').innerHTML = '<tr><td colspan="4" class="px-6 py-10 text-center text-gray-500">Select a bucket to view objects</td></tr>';
            }
            loadBuckets();
        } else {
            const data = await response.json();
            showToast(data.error || 'Failed to delete bucket', 'error');
        }
    } catch (error) {
        showToast('Error deleting bucket', 'error');
    }
}

// --- Object Operations ---
async function loadObjects(bucketName) {
    const objectList = document.getElementById('object-list');
    objectList.innerHTML = '<tr><td colspan="4" class="px-6 py-10 text-center"><div class="animate-pulse h-4 bg-gray-200 rounded w-1/2 mx-auto"></div></td></tr>';

    try {
        const response = await fetch(`${API_BASE}/buckets/${bucketName}/objects`);
        const objects = await response.json();

        objectList.innerHTML = '';
        if (objects.length === 0) {
            objectList.innerHTML = '<tr><td colspan="4" class="px-6 py-10 text-center text-gray-500">No objects found in this bucket</td></tr>';
            return;
        }

        objects.forEach(obj => {
            const tr = document.createElement('tr');
            tr.className = 'hover:bg-gray-50 transition';
            tr.innerHTML = `
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 flex items-center">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-400 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                    </svg>
                    ${obj.Key}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${formatBytes(obj.Size)}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${new Date(obj.LastModified).toLocaleString()}</td>
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <a href="${API_BASE}/buckets/${bucketName}/objects/${obj.Key}" class="text-blue-600 hover:text-blue-900 mr-4" download>Download</a>
                    <button onclick="deleteObject('${obj.Key}')" class="text-red-600 hover:text-red-900">Delete</button>
                </td>
            `;
            objectList.appendChild(tr);
        });
    } catch (error) {
        showToast('Failed to load objects', 'error');
        console.error(error);
    }
}

async function handleFileUpload(input) {
    if (!currentBucket) {
        showToast('Please select a bucket first', 'error');
        input.value = '';
        return;
    }

    const file = input.files[0];
    if (!file) return;

    const formData = new FormData();
    formData.append('file', file);

    try {
        showToast(`Uploading ${file.name}...`);
        const response = await fetch(`${API_BASE}/buckets/${currentBucket}/objects`, {
            method: 'POST',
            body: formData
        });

        if (response.ok) {
            showToast('File uploaded successfully');
            loadObjects(currentBucket);
        } else {
            const data = await response.json();
            showToast(data.error || 'Upload failed', 'error');
        }
    } catch (error) {
        showToast('Error uploading file', 'error');
    } finally {
        input.value = '';
    }
}

async function deleteObject(objectKey) {
    if (!confirm(`Are you sure you want to delete "${objectKey}"?`)) return;

    try {
        const response = await fetch(`${API_BASE}/buckets/${currentBucket}/objects/${objectKey}`, {
            method: 'DELETE'
        });

        if (response.ok) {
            showToast(`Object ${objectKey} deleted`);
            loadObjects(currentBucket);
        } else {
            const data = await response.json();
            showToast(data.error || 'Delete failed', 'error');
        }
    } catch (error) {
        showToast('Error deleting object', 'error');
    }
}

function refreshObjects() {
    if (currentBucket) {
        loadObjects(currentBucket);
    }
}

// --- UI Helpers ---
function showCreateBucketModal() {
    document.getElementById('create-bucket-modal').classList.remove('hidden');
}

function closeCreateBucketModal() {
    document.getElementById('create-bucket-modal').classList.add('hidden');
}

function showToast(message, type = 'success') {
    const toast = document.getElementById('toast');
    const msg = document.getElementById('toast-message');
    msg.textContent = message;
    toast.className = `fixed bottom-5 right-5 px-6 py-3 rounded-lg shadow-lg transition-opacity duration-300 ${type === 'error' ? 'bg-red-600' : 'bg-gray-800'} text-white`;
    toast.classList.remove('hidden');
    setTimeout(() => {
        toast.classList.add('hidden');
    }, 3000);
}

function formatBytes(bytes, decimals = 2) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}
