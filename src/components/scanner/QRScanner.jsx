import React, { useState, useRef, useEffect, useCallback } from 'react';
import { motion } from 'framer-motion';
import { Camera, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import jsQR from 'jsqr';

export default function QRScanner({ onScan, isProcessing }) {
  const videoRef = useRef(null);
  const canvasRef = useRef(null);
  const streamRef = useRef(null);
  const animationRef = useRef(null);
  const lastScannedRef = useRef('');
  const lastScanTimeRef = useRef(0);

  const [cameraActive, setCameraActive] = useState(false);
  const [pendingStream, setPendingStream] = useState(null);
  const [error, setError] = useState(null);

  const stopCamera = useCallback(() => {
    if (animationRef.current) {
      cancelAnimationFrame(animationRef.current);
      animationRef.current = null;
    }
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(t => t.stop());
      streamRef.current = null;
    }
    setCameraActive(false);
    setPendingStream(null);
  }, []);

  const scanFrame = useCallback(() => {
    const video = videoRef.current;
    const canvas = canvasRef.current;
    if (!video || !canvas || video.readyState < video.HAVE_ENOUGH_DATA) {
      animationRef.current = requestAnimationFrame(scanFrame);
      return;
    }

    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    const ctx = canvas.getContext('2d');
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const code = jsQR(imageData.data, imageData.width, imageData.height, {
      inversionAttempts: 'dontInvert',
    });

    if (code) {
      const now = Date.now();
      const value = code.data;
      if (value !== lastScannedRef.current || now - lastScanTimeRef.current > 5000) {
        lastScannedRef.current = value;
        lastScanTimeRef.current = now;
        onScan(value);
      }
    }

    animationRef.current = requestAnimationFrame(scanFrame);
  }, [onScan]);

  // Once cameraActive=true the video element renders; attach stream here
  useEffect(() => {
    if (!cameraActive || !pendingStream) return;

    const video = videoRef.current;
    if (!video) return;

    streamRef.current = pendingStream;
    video.srcObject = pendingStream;

    const onPlaying = () => {
      animationRef.current = requestAnimationFrame(scanFrame);
    };

    video.addEventListener('playing', onPlaying);
    video.play().catch(() => {});

    return () => {
      video.removeEventListener('playing', onPlaying);
    };
  }, [cameraActive, pendingStream, scanFrame]);

  useEffect(() => {
    return () => stopCamera();
  }, [stopCamera]);

  const startCamera = async () => {
    setError(null);
    if (!window.isSecureContext) {
      setError(
        'Camera needs HTTPS (or localhost on this device). From your phone use https://YOUR_PC_IP:5173 after restarting npm run dev, and tap through Safari’s certificate warning once.'
      );
      return;
    }
    if (!navigator.mediaDevices?.getUserMedia) {
      setError('This browser does not support camera access here.');
      return;
    }
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: { ideal: 'environment' } },
        audio: false,
      });
      // Set stream first, then flip cameraActive so video element mounts
      setPendingStream(stream);
      setCameraActive(true);
    } catch (err) {
      const name = err?.name || '';
      if (name === 'NotAllowedError' || name === 'PermissionDismissedError') {
        setError('Camera permission was blocked. Allow camera for this site in your browser or system settings.');
      } else if (name === 'NotFoundError' || name === 'DevicesNotFoundError') {
        setError('No camera was found on this device.');
      } else if (name === 'NotReadableError' || name === 'TrackStartError') {
        setError('Camera is already in use or could not be started. Close other apps using the camera and try again.');
      } else {
        setError('Camera access was denied or is unavailable.');
      }
    }
  };

  return (
    <div className="relative">
      {!cameraActive ? (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="flex flex-col items-center justify-center py-16 px-6"
        >
          <div className="w-24 h-24 rounded-3xl bg-accent flex items-center justify-center mb-6">
            <Camera className="w-10 h-10 text-accent-foreground" strokeWidth={1.5} />
          </div>
          <h2 className="text-lg font-semibold mb-1.5">Ready to Scan</h2>
          <p className="text-sm text-muted-foreground text-center max-w-[260px] mb-6 leading-relaxed">
            Point your camera at a receipt QR code to instantly save it.
          </p>
          {error && (
            <p className="text-xs text-destructive mb-4 text-center bg-destructive/10 rounded-xl px-4 py-2">{error}</p>
          )}
          <Button onClick={startCamera} className="rounded-xl px-8 h-12 font-medium text-base">
            <Camera className="w-5 h-5 mr-2" />
            Open Camera
          </Button>
        </motion.div>
      ) : (
        <motion.div
          initial={{ opacity: 0, scale: 0.97 }}
          animate={{ opacity: 1, scale: 1 }}
          className="relative"
        >
          <div className="relative rounded-2xl overflow-hidden bg-black mx-auto" style={{ aspectRatio: '3/4', maxHeight: '65vh' }}>
            {/* The video element always renders when cameraActive=true */}
            <video
              ref={videoRef}
              className="w-full h-full object-cover"
              playsInline
              autoPlay
              muted
            />

            {/* Scan overlay */}
            <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
              <div className="relative w-56 h-56">
                <div className="absolute top-0 left-0 w-8 h-8 border-t-2 border-l-2 border-white/80 rounded-tl-lg" />
                <div className="absolute top-0 right-0 w-8 h-8 border-t-2 border-r-2 border-white/80 rounded-tr-lg" />
                <div className="absolute bottom-0 left-0 w-8 h-8 border-b-2 border-l-2 border-white/80 rounded-bl-lg" />
                <div className="absolute bottom-0 right-0 w-8 h-8 border-b-2 border-r-2 border-white/80 rounded-br-lg" />
                <motion.div
                  className="absolute left-2 right-2 h-0.5 bg-primary/90 rounded-full"
                  animate={{ top: ['8%', '88%', '8%'] }}
                  transition={{ duration: 2.5, repeat: Infinity, ease: 'easeInOut' }}
                />
              </div>
            </div>
          </div>

          <div className="flex justify-center mt-4">
            <Button variant="outline" onClick={stopCamera} className="rounded-xl h-10 px-6">
              <X className="w-4 h-4 mr-2" />
              Close Camera
            </Button>
          </div>

          {isProcessing && (
            <div className="absolute inset-0 bg-background/80 backdrop-blur-sm rounded-2xl flex items-center justify-center">
              <div className="flex flex-col items-center gap-3">
                <div className="w-8 h-8 border-2 border-muted border-t-primary rounded-full animate-spin" />
                <p className="text-sm font-medium">Processing receipt...</p>
              </div>
            </div>
          )}
        </motion.div>
      )}
      <canvas ref={canvasRef} className="hidden" />
    </div>
  );
}