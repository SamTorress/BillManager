<?php

namespace App\Http\Controllers;

use App\Models\Bill;
use App\Http\Resources\BillResource;
use App\Http\Requests\StoreBillRequest;
use Illuminate\Http\Request;
use App\Http\Requests\UpdateBillRequest;

class BillController extends Controller
{
    /**
     * Display a listing of the resource.
     * ActiveStudent: only their own bills. Accounting: all bills.
     */
    public function index(Request $request)
    {
        $roles = $request->attributes->get('jwt_roles', []);
        $username = $request->attributes->get('jwt_username');

        if (in_array('Accounting', $roles)) {
            $bills = Bill::all();
        } elseif (in_array('ActiveStudent', $roles)) {
            $bills = Bill::where('owner', $username)->get();
        } else {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        return BillResource::collection($bills);
    }

    /**
     * Store a newly created resource in storage.
     * ActiveStudent only. Owner is always derived from the JWT, never trusted from the request body.
     */
    public function store(StoreBillRequest $request)
    {
        $roles = $request->attributes->get('jwt_roles', []);
        if (!in_array('ActiveStudent', $roles)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $validated = $request->validated();

        $bill = Bill::create([
            'payee_name' => $validated['payeeName'],
            'due_date' => $validated['dueDate'],
            'payment_due' => $validated['paymentDue'],
            'paid' => $validated['paid'] ?? false,
            'owner' => $request->attributes->get('jwt_username'),
        ]);

        $bill->refresh();

        return response()
            ->json(new BillResource($bill), 201)
            ->header('Location', route('bills.show', $bill));
    }

    /**
     * Display the specified resource.
     * ActiveStudent only, and only if they own it. 403/404 for another user's bill.
     */
    public function show(Request $request, string $id)
    {
        $roles = $request->attributes->get('jwt_roles', []);
        if (!in_array('ActiveStudent', $roles)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $bill = Bill::findOrFail($id);

        if ($bill->owner !== $request->attributes->get('jwt_username')) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        return new BillResource($bill);
    }

    /**
     * Update the specified resource in storage.
     * ActiveStudent only, and only if they own it.
     */
    public function update(UpdateBillRequest $request, string $id)
    {
        $roles = $request->attributes->get('jwt_roles', []);
        if (!in_array('ActiveStudent', $roles)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $bill = Bill::findOrFail($id);

        if ($bill->owner !== $request->attributes->get('jwt_username')) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $validated = $request->validated();

        if ($bill->version !== $validated['version']) {
            return response()->json([
                'message' => 'The data you are trying to update has changed since your last read request.',
            ], 400);
        }

        $bill->payee_name = $validated['payeeName'];
        $bill->due_date = $validated['dueDate'];
        $bill->payment_due = $validated['paymentDue'];
        $bill->paid = $validated['paid'] ?? false;
        $bill->version = $bill->version + 1;

        $bill->save();
        $bill->refresh();

        return new BillResource($bill);
    }

    /**
     * Remove the specified resource from storage.
     * ActiveStudent only, and only if they own it.
     */
    public function destroy(Request $request, string $id)
    {
        $roles = $request->attributes->get('jwt_roles', []);
        if (!in_array('ActiveStudent', $roles)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $bill = Bill::findOrFail($id);

        if ($bill->owner !== $request->attributes->get('jwt_username')) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $bill->delete();

        return response()->json(null, 204);
    }
}
