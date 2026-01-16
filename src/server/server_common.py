import numpy as np
import json
from collections import defaultdict


# image format is length, width, height
# I assume grayscale for now.
IMAGE_INFO_FORMAT = "%d,%d,%d"
my_inverted_dict = defaultdict(list)

# actions encoding
CLASSIFY_PDF_ACTION = "1"
ACTIONS_MESSAGE = "{0}) classify pdf".format(CLASSIFY_PDF_ACTION)
VALID_ACTIONS = [CLASSIFY_PDF_ACTION]

END_MSG = b"END"
GOOD_ACTION = b'\x01'
BAD_ACTION = b'\x02'

# actions int

# SOME CONFIGS
# match version to verify that client and server are at sink
VERSION = B"0.1"

DATA_BUFFER_SIZE = 0x1000

def int_to_bytes(x: int) -> bytes:
    return x.to_bytes((x.bit_length() + 7) // 8, 'big')

def int_from_bytes(xbytes: bytes) -> int:
    return int.from_bytes(xbytes, 'big')

class SocketException(Exception):
    pass


def send_dict(sock, send_dict):
    """
    send dict lenght and then the dict itself
    @param sock: socket
    @param result_dict: dict to send
    @return:
    """
    # do i just pickle the dict and send it? i can just json it tbh it will be simpler
    dict_json = bytes(json.dumps(send_dict), "utf-8")

    # results back to the server
    sock.sendall(int_to_bytes(len(dict_json)))
    sock.sendall(dict_json)
    # sock.sendall(bytes("ALL_GOOD"))


def recv_dict(sock):
    """
    receive dict lenght and then the dict itself
    @param sock:
    @return:
    """
    dict_length = sock.recv(1024)
    if len(dict_length) == 0:
        raise SocketException("disconnected when receiving result dict")

    dict_length = int_from_bytes(dict_length)

    dict_json = sock.recv(dict_length)
    if len(dict_json) == 0:
        raise SocketException("disconnected when receiving result dict")

    result_dict = json.loads(dict_json.decode("utf-8"))
    return result_dict

def send_network_img_array(sock, img_array):
    for img in img_array:
        send_network_image(sock, img)
    # excpect this to go withouit errors, unless the socket throws any errors
    sock.sendall(END_MSG)

    # receive validation on cllassification
    success_code = sock.recv(1024)
    if len(success_code) == 0:
        raise SocketException("socket disconnected after sending images for classification")
    if success_code != GOOD_ACTION:
        return False
    return True


def send_network_image(sock, img :np.ndarray):
    """
    send image through sock
    @param sock:
    @param img:
    @return:
    """
    # convert image to numpy
    img = np.asarray(img)
    # see that shape is 2d and not 3d
    #print("image shape: ", img.shape)

    img_length = img.shape[0] * img.shape[1]
    # image length can be inferred from shape, but i will send it to
    img_info = b','.join([int_to_bytes(img_length), int_to_bytes(img.shape[0]), int_to_bytes(img.shape[1])])
    # send image info
    sock.sendall(img_info)
    # send image as bytes, send buffered
    img_bytes = img.tobytes()
    for i in range(0, img_length, DATA_BUFFER_SIZE):
        sock.sendall(img_bytes[i:i+DATA_BUFFER_SIZE])


def receive_network_image(sock):
    """
    get an image
    @param sock:
    @return:
    """
    image_info = sock.recv(1024)
    if image_info == END_MSG:
        # if return is none, then this means end
        return None

    image_info = image_info.split(b",")
    if len(image_info) != 3:
        raise ValueError(f"invalid message info: {image_info}")
    try:

        img_length = int_from_bytes(image_info[0])
        img_width = int_from_bytes(image_info[1])
        img_height = int_from_bytes(image_info[2])
        if img_length != img_height * img_width:
            # somthing went wrong...
            raise ValueError(f"invalid message info: {image_info}")
    except ValueError as e:
        raise ValueError(f"invalid message info: {image_info}")

    # received buffered input:
    img = bytearray(img_length)
    for i in range(0, img_length, DATA_BUFFER_SIZE):
        img[i:i + DATA_BUFFER_SIZE] = sock.recv(DATA_BUFFER_SIZE)
    np_img = (np.frombuffer(img, dtype="uint8").reshape((img_width, img_height)))
    return np_img

"""
image_info = sock.recv(1024)
    if image_info == END_MSG:
        # if return is none, then this means end
        return None


    image_info = image_info.split(",")
    if len(image_info != 3):
        raise ValueError(f"invalid message info: {image_info}")
    try:
        img_length = int(image_info[0])
        img_width = int(image_info[1])
        img_height = int(image_info[2])
        
    except ValueError as e:
        raise ValueError(f"invalid message info: {image_info}")
"""