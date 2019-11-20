import cv2

capture = cv2.VideoCapture(0)
#fourcc = cv2.VideoWriter_fourcc(*'mp4v')

capture.set(cv2.CAP_PROP_FRAME_WIDTH, 1920)
capture.set(cv2.CAP_PROP_FRAME_HEIGHT, 1080)

while True:
	ret, frame = capture.read()
	image = frame.copy()

	cv2.imshow("video1", image)

	if cv2.waitKey(1) > 0: break

capture.release()
cv2.destroyAllWindows()