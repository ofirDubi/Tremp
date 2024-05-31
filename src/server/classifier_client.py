import socket
import ssl
import itertools
import json
from utils import add_extension, merge_pages, CLASSIFIER_QA_SUFFIX, CLASSIFICATION_PATH_SUFFIX
from server.server_common import send_network_img_array, GOOD_ACTION, VERSION,\
    recv_dict, VALID_ACTIONS, CLASSIFY_PDF_ACTION, SocketException
# from server_common import send_network_img_array, GOOD_ACTION, VERSION,\
#     recv_dict, VALID_ACTIONS, CLASSIFY_PDF_ACTION, SocketException

import os
from pdf_actions import get_images_from_pdf, split_pdf, add_page_numgers


def start_client_side_thread(config):
    HOST = config['host']
    PORT = config['port']
    pemServer = config['servercrt']
    keyClient = config['clientkey']
    pemClient = config['cliencrt']

    print(f"trying to connect to {HOST}:{PORT}")

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setblocking(1)
    sock.connect((HOST, PORT))

    context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
    context.verify_mode = ssl.CERT_REQUIRED
    context.load_verify_locations(pemServer)
    context.load_cert_chain(certfile=pemClient, keyfile=keyClient)

    if ssl.HAS_SNI:
        secure_sock = context.wrap_socket(sock, server_side=False, server_hostname=HOST)
    else:
        secure_sock = context.wrap_socket(sock, server_side=False)

    cert = secure_sock.getpeercert()
    #print(pprint.pformat(cert))

    # verify server
    if not cert or ('organizationName', 'Best Med Opinion') not in itertools.chain(*cert['subject']): raise Exception("ERROR")
    print(f"[+] Established secure connected with server at {HOST}:{PORT}")

    # send version to the server, and see if the server accepts
    try:
        secure_sock.sendall(VERSION)
        server_version = secure_sock.recv(1024)
        if server_version != VERSION:
            print(f"[-] ERROR: mismatch in client-server version, client is {VERSION} while server is {server_version}")
        else:
            # if versions match, continue
            send_commands(secure_sock)
    finally:
        secure_sock.close()
        sock.close()

def send_pdf_to_classify(sock):
    """
    get images from the pdf and send them
    @return:
    """
    # get pdf input from used
    input_filename = input("Enter input filename: ").strip()
    input_filename = add_extension(input_filename)
    if not os.path.exists(input_filename):
        print("file doesn't exists:", input_filename)
        return

    output_path = input_filename + CLASSIFICATION_PATH_SUFFIX

    print("[+] Getting images from pdf...")
    images = get_images_from_pdf(input_filename)
    # send images to be processed
    print("[+] Sending images to classification server...")
    success = send_network_img_array(sock, images)
    if not success:
        print("[-] ERROR: server failed to classify images, look at server logs for more information")
        return

    # receive result dict from the server, this should be good
    print("[+] Received result from classification server, splitting pdf...")
    result_dict = recv_dict(sock)

    # save result dict, as pdf name + json. this will be used later for QA
    if not os.path.exists(output_path):
        os.makedirs(output_path)
    print(os.path.join(output_path, input_filename.replace(".pdf", CLASSIFIER_QA_SUFFIX)))
    json.dump(result_dict, open(os.path.join(output_path, input_filename.replace(".pdf", CLASSIFIER_QA_SUFFIX)), "w"))

    # add page numbers before splitting
    numbered_pdf = add_page_numgers(input_filename)

    sections = []
    for key in result_dict.keys():
        sections.append([os.path.join(output_path, key+".pdf")] + merge_pages(result_dict[key]))
    print(sections)
    split_pdf(numbered_pdf, sections)
    print("[+] Done.")
    # should i delete the numbered pdf? idk
def send_commands(sock):
    # receive some greetings message
    hello_msg = sock.recv(1024)
    print(hello_msg.decode("utf-8"))

    actions = sock.recv(1024)
    if len(actions) == 0:
        print("server error, dissconnected")
        return
    print(actions.decode("utf-8"))

    while True:
        """
        process of sending messages:
        action = client->input() 
        # client validates input...
        client->send(action) # (str encoding of action)
        server->recv(action) # str, server validast
        
        # server validates input and sends response...
        server->send(is_action_valid) 
        client->recv(is_action_valid)
        
        # if the action is valid, client and server pass to the command logic 
        """

        print("enter \"END\" to disconnect from the server and ")
        action = input("$ ")
        if action == "END" or action == "end":
            break
        if action not in VALID_ACTIONS:
            print("invalid input: ", action)
            continue

        sock.sendall(bytes(action, encoding="utf-8"))
        res = sock.recv(1024)
        if not res:
            raise SocketException("server disconnected")
        if res != GOOD_ACTION:
            print("sent bad action to server :(", res)

        # if the server accepted out action, lets process it
        if action == CLASSIFY_PDF_ACTION:
            send_pdf_to_classify(sock)
        else:
            print("idk how i got here...")
            raise ValueError("bad action: ", action)

CLIENT_CONFIG = "client_config.json"

def start_classification_client():
    if not os.path.exists(CLIENT_CONFIG):
        client_config_bin = os.path.join("bin", CLIENT_CONFIG)
        if not os.path.exists(client_config_bin):
            print(f"[-] ERROR: couldn't find configuration file: {CLIENT_CONFIG}")
            return
    config = json.load(open(CLIENT_CONFIG, "r"))
    print("[+] Welcome to BESTMED SUPER-AI")
    print("[+] File input file should contain images (no OCR)")
    print(f"[+] Client configuration can be changed in {CLIENT_CONFIG}")

    try:
        start_client_side_thread(config)
    except SocketException as e:
        print("[-] ERROR: connection was unexpectedly closed: ", e)
    except ConnectionResetError as e:
        print("[-] ERROR: connection was unexpectedly closed: ", e)

def main():

    # config = {}
    # config['host'] = '109.186.56.70'
    # config['port'] = 11881
    # config['servercrt'] = "certs/server.crt"
    # config['clientkey'] = "certs/client1.key"
    # config['cliencrt'] = "certs/client1.crt"
    # json.dump(config, open("client_config.json", "w"))
    # config = json.load(open("client_config.json", "r"))
    #
    # start_client_side_thread(config)
    start_classification_client()



if __name__ == '__main__':
    main()