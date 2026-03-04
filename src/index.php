<?php

declare(strict_types=1);

const ALLOWED_EXTENSIONS = ['xml'];
const MAX_FILE_SIZE = 10485760; // 10MB

class PageToAltoConverter
{
    private string $tempDir;

    public function __construct(?string $tempDir = null)
    {
        $this->tempDir = $tempDir ?? sys_get_temp_dir();
    }

    public function convert(string $inputFile): array
    {
        if (!file_exists($inputFile)) {
            return $this->error('Input file does not exist');
        }

        $normalizedFile = $this->generateTempFile('page_');
        $outputFile     = $this->generateTempFile('alto_');

        try {
            $command = $this->buildCommand($inputFile, $normalizedFile, $outputFile);

            exec($command, $output, $returnCode);

            if ($returnCode !== 0) {
                return $this->error('Conversion failed: ' . implode("\n", $output));
            }

            if (!file_exists($outputFile)) {
                return $this->error('Output file was not created');
            }

            $content = file_get_contents($outputFile);

            return $this->success($content);
        } finally {
            if (is_file($normalizedFile)) {
                @unlink($normalizedFile);
            }

            if (is_file($outputFile)) {
                @unlink($outputFile);
            }
        }
    }

    private function buildCommand(string $input, string $normalized, string $output): string
    {
        return sprintf(
            'transkribus-to-prima %s > %s && page-to-alto --alto-version 4.2 --no-check-words %s -O %s 2>&1',
            escapeshellarg($input),
            escapeshellarg($normalized),
            escapeshellarg($normalized),
            escapeshellarg($output)
        );
    }

    private function generateTempFile(string $prefix): string
    {
        return tempnam($this->tempDir, $prefix . bin2hex(random_bytes(4)) . '_');
    }

    private function success(string $content): array
    {
        return ['success' => true, 'content' => $content];
    }

    private function error(string $message): array
    {
        return ['success' => false, 'error' => $message];
    }
}

class FileUploadHandler
{
    public function handleUpload(string $key): array
    {
        if (!array_key_exists($key, $_FILES)) {
            return $this->error('No file uploaded');
        }

        $file = $_FILES[$key];

        if ($file['error'] !== UPLOAD_ERR_OK) {
            return $this->error($this->getUploadErrorMessage($file['error']));
        }

        if (!$this->isValidFile($file)) {
            return $this->error('Invalid file type or size');
        }

        return $this->success($file['tmp_name']);
    }

    private function isValidFile(array $file): bool
    {
        $extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        return in_array($extension, ALLOWED_EXTENSIONS) 
            && $file['size'] <= MAX_FILE_SIZE;
    }

    private function getUploadErrorMessage(int $error): string
    {
        $errors = [
            UPLOAD_ERR_INI_SIZE => 'File exceeds upload_max_filesize',
            UPLOAD_ERR_FORM_SIZE => 'File exceeds MAX_FILE_SIZE',
            UPLOAD_ERR_PARTIAL => 'File was only partially uploaded',
            UPLOAD_ERR_NO_FILE => 'No file was uploaded',
            UPLOAD_ERR_NO_TMP_DIR => 'Missing temporary folder',
            UPLOAD_ERR_CANT_WRITE => 'Failed to write file to disk',
            UPLOAD_ERR_EXTENSION => 'Upload stopped by extension',
        ];

        return $errors[$error] ?? 'Unknown upload error';
    }

    private function success(string $tmpName): array
    {
        return ['success' => true, 'file' => $tmpName];
    }

    private function error(string $message): array
    {
        return ['success' => false, 'error' => $message];
    }
}

function getBearerToken(): ?string
{
    $headers = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['Authorization'] ?? '';
    if (function_exists('apache_request_headers') && empty($headers)) {
        $apacheHeaders = apache_request_headers();
        $headers = $apacheHeaders['Authorization'] ?? '';
    }

    if (preg_match('/Bearer\s(\S+)/', $headers, $matches)) {
        return $matches[1];
    }

    return null;
}

function requireBearerToken($authToken): void
{
    $token = getBearerToken();
    if ($token === null) {
        http_response_code(401);
        header('WWW-Authenticate: Bearer');
        exit('Missing or invalid Authorization header');
    }

    if (!hash_equals($authToken, $token)) {
        http_response_code(401);
        header('WWW-Authenticate: Bearer error="invalid_token"');
        exit('Invalid token');
    }
}

// always require token
requireBearerToken(getenv('UPLOAD_KEY'));

$response = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $uploadHandler = new FileUploadHandler();
    $uploadResult = $uploadHandler->handleUpload('file');

    if ($uploadResult['success']) {
        $converter = new PageToAltoConverter();
        $conversionResult = $converter->convert($uploadResult['file']);

        if ($conversionResult['success']) {
            header('Content-Type: application/xml');
            header('Content-Disposition: attachment; filename="converted.alto.xml"');
            echo $conversionResult['content'];
            exit;
        } else {
            $response = $conversionResult;
        }
    } else {
        $response = $uploadResult;
    }

    http_response_code(400);
    header('Content-Type: application/json');
    echo json_encode($response);
    exit;
}

http_response_code(405);
exit;
