import cv2

capture = cv2.VideoCapture(0)
capture.set(cv2.CAP_PROP_FRAME_WIDTH, 3840)
capture.set(cv2.CAP_PROP_FRAME_HEIGHT, 1080)

while True:
	ret, frame = capture.read()
	image = frame.copy()
	image_1 = image[0:1080,	0:1920]
	image_2 = image[0:1080, 1920:3840]

	cv2.imshow("video1", image_1)
	cv2.imshow("video2", image_2)

	if cv2.waitKey(1) > 0: break

capture.release()
cv2.destroyAllWindows()