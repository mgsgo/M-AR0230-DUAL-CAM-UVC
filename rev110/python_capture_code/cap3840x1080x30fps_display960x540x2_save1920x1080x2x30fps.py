import cv2
capture = cv2.VideoCapture(0)
fourcc = cv2.VideoWriter_fourcc(*'mp4v')
capture.set(cv2.CAP_PROP_FRAME_WIDTH,  3840)
capture.set(cv2.CAP_PROP_FRAME_HEIGHT, 1080)

writer_1 = cv2.VideoWriter('1920x1080_cam1.mp4', fourcc, 30.0, (1920,1080))
writer_2 = cv2.VideoWriter('1920x1080_cam2.mp4', fourcc, 30.0, (1920,1080))

while True:
	ret, frame = capture.read()
	image = frame.copy()
	image_1 = image[0:1080,	0:1920]
	image_2 = image[0:1080, 1920:3840]

	writer_1.write(image_1)
	writer_2.write(image_2)

	image_1 = cv2.resize(image_1, (960, 540))
	image_2 = cv2.resize(image_2, (960, 540))

	cv2.imshow("video1", image_1)
	cv2.imshow("video2", image_2)

	if cv2.waitKey(1) > 0: break

capture.release()
cv2.destroyAllWindows()